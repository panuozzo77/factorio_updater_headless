#!/bin/bash

# Define variables
LATEST_RELEASES_URL="https://factorio.com/api/latest-releases"  # URL for latest releases
INSTALLED_TAR="factorio-installed.tar.xz"  # Path to installed tar.xz
FACTORIO_DIR="factorio"  # Directory containing Factorio files
LOG_FILE="logfile.log"  # Change this to your desired log file path

TMUX_SESSION="mysession"  # Name of your tmux session
FACTORIO_WINDOW="factorio" # Name of the tmux window running Factorio

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if Factorio server is running
is_factorio_running() {
    pgrep -f 'factorio/bin/x64/factorio'
}

# Function to stop the Factorio server
stop_factorio() {
    log "Sending /quit command to tmux session: $TMUX_SESSION, window: $FACTORIO_WINDOW"
    tmux send-keys -t "$TMUX_SESSION:$FACTORIO_WINDOW" '/quit' C-m

    if [ $? -eq 0 ]; then
        log "Command sent successfully."
    else
        log "Failed to send command."
    fi

    sleep 5

    if is_factorio_running; then
        log "Error: Factorio server is still running."
    else
        log "Success: Factorio server has stopped."
    fi
}

# Function to check and update Factorio if necessary
check_and_update_factorio() {
    # Fetch the latest version information from the API
    LATEST_VERSION=$(curl -s "$LATEST_RELEASES_URL" | jq -r '.stable.headless')

    # Check if we found a version
    if [ -z "$LATEST_VERSION" ]; then
        log "No headless version found in the API response."
        exit 1
    fi

    # Get the currently installed version from Factorio
    CURRENT_VERSION=$($FACTORIO_DIR/bin/x64/factorio --version | grep "Version:" | head -n 1 | awk '{print $2}')

    # Compare versions and check if an update is needed
    if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
        log "A new version ($LATEST_VERSION) is available! Actual is ($CURRENT_VERSION)"
       
        # Download the latest version tar.xz
        DOWNLOAD_URL="https://factorio.com/get-download/stable/headless/linux64"  # Update this URL if needed
        wget -q "$DOWNLOAD_URL" -O "$INSTALLED_TAR"
        
        log "Updating Factorio server..."
        
        # Create a temporary extraction directory
        TEMP_DIR=$(mktemp -d)
        
        # Extract to temporary directory
        tar -xf "$INSTALLED_TAR" -C "$TEMP_DIR"

        # stopping the execution
        stop_factorio
        
        # Move preserved files back to the main directory
        cp -r "$FACTORIO_DIR/temp/"* "$TEMP_DIR/factorio/temp/" 2>/dev/null || true
        cp "$FACTORIO_DIR/player-data.json" "$TEMP_DIR/factorio/player-data.json" 2>/dev/null || true
        cp -r "$FACTORIO_DIR/mods/"* "$TEMP_DIR/factorio/mods/" 2>/dev/null || true
        
        # Replace old files with new ones from temporary directory, avoiding nested factorio folder issue
        rsync -av --exclude={temp,player-data.json,mods} "$TEMP_DIR/factorio/" "$FACTORIO_DIR/"
        
        # Clean up temporary directory
        rm -rf "$TEMP_DIR"
        
        # Command to run the server (update this path as necessary)
        tmux send-keys -t "$TMUX_SESSION:$FACTORIO_WINDOW" './start.sh'
        log "Update Process Completed."
    else
        log "You are using the latest version ($CURRENT_VERSION). No update needed."
    fi

}

# Check if Factorio server is running before proceeding with update process
if is_factorio_running; then
    log "Factorio server is running. Checking for updates..."
    
    check_and_update_factorio

else
    log "Factorio server is not running. Updates won't be checked..."
    # do nothing
    # check_and_update_factorio
fi
