#!/bin/sh

# Generate config.json from environment variables
# This script runs at container startup to create the frontend configuration

CONFIG_FILE="/usr/share/nginx/html/config.json"
CONFIG_DIR=$(dirname "$CONFIG_FILE")

# Ensure the directory exists
mkdir -p "$CONFIG_DIR"

# Function to convert comma-separated string to JSON array
to_json_array() {
    if [ -z "$1" ]; then
        echo "[]"
    else
        echo "$1" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/'
    fi
}

# Function to convert boolean string to JSON boolean
to_json_boolean() {
    case "$1" in
        true|TRUE|True|1|yes|YES|Yes)
            echo "true"
            ;;
        *)
            echo "false"
            ;;
    esac
}

# Start building the JSON configuration
cat > "$CONFIG_FILE" << EOF
{
EOF

# Add title (default: "Infrastructure Status")
TITLE="${CONFIG_TITLE:-Infrastructure Status}"
echo "  \"title\": \"$TITLE\"," >> "$CONFIG_FILE"

# Add gatusBaseUrl if provided
if [ -n "$CONFIG_GATUS_BASE_URL" ]; then
    echo "  \"gatusBaseUrl\": \"$CONFIG_GATUS_BASE_URL\"," >> "$CONFIG_FILE"
fi

# Add hideUrls boolean (default: false)
HIDE_URLS=$(to_json_boolean "$CONFIG_HIDE_URLS")
echo "  \"hideUrls\": $HIDE_URLS," >> "$CONFIG_FILE"

# Add hideFooter boolean (default: false)
HIDE_FOOTER=$(to_json_boolean "$CONFIG_HIDE_FOOTER")
echo "  \"hideFooter\": $HIDE_FOOTER," >> "$CONFIG_FILE"

# Add hiddenGroups array
HIDDEN_GROUPS=$(to_json_array "$CONFIG_HIDDEN_GROUPS")
echo "  \"hiddenGroups\": $HIDDEN_GROUPS," >> "$CONFIG_FILE"

# Add hiddenStatuses array
HIDDEN_STATUSES=$(to_json_array "$CONFIG_HIDDEN_STATUSES")
echo "  \"hiddenStatuses\": $HIDDEN_STATUSES," >> "$CONFIG_FILE"

# Add groupOrder array
GROUP_ORDER=$(to_json_array "$CONFIG_GROUP_ORDER")
echo "  \"groupOrder\": $GROUP_ORDER," >> "$CONFIG_FILE"

# Add defaultExpandGroups boolean (default: false)
DEFAULT_EXPAND_GROUPS=$(to_json_boolean "$CONFIG_DEFAULT_EXPAND_GROUPS")
echo "  \"defaultExpandGroups\": $DEFAULT_EXPAND_GROUPS," >> "$CONFIG_FILE"

# Add defaultRefreshInterval (default: 60)
DEFAULT_REFRESH_INTERVAL="${CONFIG_DEFAULT_REFRESH_INTERVAL:-60}"
echo "  \"defaultRefreshInterval\": $DEFAULT_REFRESH_INTERVAL," >> "$CONFIG_FILE"

# Add notice configuration if any notice variables are set
if [ -n "$CONFIG_NOTICE_TYPE" ] || [ -n "$CONFIG_NOTICE_TITLE" ] || [ -n "$CONFIG_NOTICE_CONTENT" ] || [ -n "$CONFIG_NOTICE_CREATED_AT" ] || [ -n "$CONFIG_NOTICE_UPDATED_AT" ]; then
    echo "  \"notice\": {" >> "$CONFIG_FILE"
    
    # Add notice type if provided
    if [ -n "$CONFIG_NOTICE_TYPE" ]; then
        echo "    \"type\": \"$CONFIG_NOTICE_TYPE\"," >> "$CONFIG_FILE"
    fi
    
    # Add notice title (default: empty string)
    NOTICE_TITLE="${CONFIG_NOTICE_TITLE:-}"
    echo "    \"title\": \"$NOTICE_TITLE\"," >> "$CONFIG_FILE"
    
    # Add notice content (default: empty string)
    NOTICE_CONTENT="${CONFIG_NOTICE_CONTENT:-}"
    echo "    \"content\": \"$NOTICE_CONTENT\"," >> "$CONFIG_FILE"
    
    # Add notice createdAt if provided
    if [ -n "$CONFIG_NOTICE_CREATED_AT" ]; then
        echo "    \"createdAt\": \"$CONFIG_NOTICE_CREATED_AT\"," >> "$CONFIG_FILE"
    fi
    
    # Add notice updatedAt if provided (remove trailing comma if this is the last item)
    if [ -n "$CONFIG_NOTICE_UPDATED_AT" ]; then
        echo "    \"updatedAt\": \"$CONFIG_NOTICE_UPDATED_AT\"" >> "$CONFIG_FILE"
    else
        # Remove the trailing comma from the last added line
        sed -i '$ s/,$//' "$CONFIG_FILE"
    fi
    
    echo "  }" >> "$CONFIG_FILE"
else
    # Remove the trailing comma from defaultRefreshInterval if no notice section
    sed -i '$ s/,$//' "$CONFIG_FILE"
fi

# Close the JSON object
echo "}" >> "$CONFIG_FILE"

echo "Configuration file generated at $CONFIG_FILE"
echo "Configuration contents:"
cat "$CONFIG_FILE"