#!/bin/bash
set -Eeo pipefail

# Function to display usage
usage() {
    ORIGIN_SCRIPT=$(basename "$0")

    echo "Usage: $ORIGIN_SCRIPT <kubernetes_object> [kubectl_args...] [-- command [args...]]"
    echo "Examples:"
    echo "  $ORIGIN_SCRIPT deployment/myapp                                   # Print all environment variables of deployment myapp"
    echo "  $ORIGIN_SCRIPT deployment/myapp -c container                      # Print environment variables from container of deployment myapp"
    echo "  $ORIGIN_SCRIPT cronjob/backup MY_VAR=override                     # Print environment variables with override"
    echo "  $ORIGIN_SCRIPT deployment/myapp -- env                            # Run local command with all environment variables of deployment myapp"
    echo "  $ORIGIN_SCRIPT deployment/myapp -c container -- env               # Run local command with environment from container"
    echo "  $ORIGIN_SCRIPT cronjob/backup MY_VAR=override -- env              # Run local command with environment override"
    exit 1
}

# Check if at least kubernetes_object is provided
if [ $# -lt 1 ]; then
    usage
fi

# Split args into kubectl_args and command
KUBECTL_ARGS=()
COMMAND_AND_ARGS=()
FOUND_SEPARATOR=0

for arg in "$@"; do
    if [ "$arg" = "--" ]; then
        FOUND_SEPARATOR=1
        continue
    fi
    
    if [ "$FOUND_SEPARATOR" -eq 0 ]; then
        KUBECTL_ARGS+=("$arg")
    else
        COMMAND_AND_ARGS+=("$arg")
    fi
done

# Temporary file to store environment variables
TMP_ENV_FILE=$(mktemp)
trap 'rm -f "$TMP_ENV_FILE"' EXIT

# Extract environment variables using kubectl set env
kubectl set env "${KUBECTL_ARGS[@]}" --resolve --list --overwrite=true --dry-run='client' \
    | grep -v '^#' \
    > "$TMP_ENV_FILE"

# Get all containers (regular and init) with their envFrom references
CONTAINERS_JSON=$(kubectl get "${KUBECTL_ARGS[0]}" -o json | \
    jq -r '
    # First, determine the path to containers based on resource type
    (if .spec.jobTemplate then
        .spec.jobTemplate.spec.template.spec
    elif .spec.template then
        .spec.template.spec
    else
        .spec
    end) as $spec |
    # Combine both regular and init containers if they exist
    {
        containers: ($spec.containers // []),
        initContainers: ($spec.initContainers // [])
    }')

# Check if we got valid JSON before proceeding
if [ $? -eq 0 ] && [ "$CONTAINERS_JSON" != "" ]; then
    # Process both container types
    echo "$CONTAINERS_JSON" | \
    jq -r '
    # Process both container arrays
    (.containers + .initContainers)[] |
    select(.envFrom) |
    .envFrom[] |
    select(.configMapRef != null or .secretRef != null) |
    if .configMapRef then
        {"type":"configmap","name":.configMapRef.name}
    else
        {"type":"secret","name":.secretRef.name}
    end |
    [.type,.name] |
    @tsv' | \
    while IFS=$'\t' read -r ref_type ref_name; do
        [ "$ref_type" = "" ] && continue
        
        case "$ref_type" in
            "configmap")
                kubectl get configmap "$ref_name" -o json 2>/dev/null | \
                    jq -r '.data // {} | to_entries | map("\(.key)=\(.value)") | .[]' || true
                ;;
            "secret")
                kubectl get secret "$ref_name" -o json 2>/dev/null | \
                    jq -r '.data // {} | to_entries | map("\(.key)=\(.value | @base64d)") | .[]' || true
                ;;
        esac
    done >> "$TMP_ENV_FILE"
fi

# # Sort and deduplicate all environment variables
# sort -u "$TMP_ENV_FILE" -o "$TMP_ENV_FILE"

# If no command is provided, just print the environment variables
if [ ${#COMMAND_AND_ARGS[@]} -eq 0 ]; then
    cat "$TMP_ENV_FILE"
    exit 0
fi

# Otherwise execute the command with the extracted environment variables
# Convert newlines to null characters and use xargs -0 to properly handle env vars
# env -v "$(cat "$TMP_ENV_FILE")" "${COMMAND_AND_ARGS[@]}"
# tr '\n' '\0' < "$TMP_ENV_FILE" | xargs -0 env "${COMMAND_AND_ARGS[@]}"

TEMP_SCRIPT=$(mktemp)
trap 'rm -f "$TEMP_SCRIPT" "$TMP_ENV_FILE"' EXIT

# Process env vars handling multiline values
{
    current_key=""
    current_value=""
    
    while IFS= read -r line; do
        if [[ $line =~ ^([^=]+)=(.*) ]]; then
            if [ -n "$current_key" ]; then
                # Escape single quotes and backslashes
                escaped_value=$(printf '%s' "$current_value" | sed "s/'/'\\\\''/g")
                printf "export %s=$'%s'\n" "$current_key" "$escaped_value"
            fi
            current_key="${BASH_REMATCH[1]}"
            current_value="${BASH_REMATCH[2]}"
        else
            current_value+=$'\n'"$line"
        fi
    done < "$TMP_ENV_FILE"
    
    # Handle last entry
    if [ -n "$current_key" ]; then
        escaped_value=$(printf '%s' "$current_value" | sed "s/'/'\\\\''/g")
        printf "export %s=$'%s'\n" "$current_key" "$escaped_value"
    fi
} > "$TEMP_SCRIPT"

# cat $TEMP_SCRIPT >&3

# Source exports and run command
source "$TEMP_SCRIPT"
exec "${COMMAND_AND_ARGS[@]}"