# Factorio_updater_headless

# Project Structure

```markdown
your pc
├── factorio_root_folder
│   ├── factorio                  # Root folder containing Factorio game files
│   ├── factorio-installed.tar.xz # Downloaded archive of the latest Factorio version
│   ├── factorio_sha256sums.txt   # Checksum file for verifying the Factorio version
│   ├── logfile.log               # Log file to track update events and errors
│   ├── **start.sh**                  # Script to start the Factorio server
│   └── **updater.sh**                # Main update script for downloading and applying updates
└── systemd_daemons
    ├── **factorio-updater.service**   # Systemd service to run the updater script
    ├── factorio-updater.timer     # Systemd timer to schedule the updater service
    ├── **start_tmux.sh**              # Script to start a tmux session for running Factorio
    └── **tmux_session.service**       # Systemd service to start the tmux session at boot
```

## What you need to do
### Prerequisites:
- A Linux server with tmux and systemd installed.
- An active Factorio headless server installation.
- Basic understanding of using bash, tmux, and systemd.

### Step-by-Step Setup
1. Place Files in the Correct Locations
    - Move the factorio_root_folder to the desired location on your server, e.g., /home/criadmin/factorio_root_folder.
    - Place the updater.sh and start.sh scripts inside factorio_root_folder.
    - Place factorio-updater.service, factorio-updater.timer, start_tmux.sh, and tmux_session.service into /etc/systemd/system/.
2. Configure the start.sh Script
```bash
#!/bin/bash
# Start the Factorio server
../factorio_root_folder/factorio/bin/x64/factorio --start-server ../factorio_root_folder/saves/my-save.zip
```
- This script is responsible for launching the Factorio server. Make sure to update the path in the script to point to your Factorio installation. Adjust the --start-server with the arguments you like
3. Configure the updater.sh Script

The updater.sh script 1) checks for new Factorio versions, 2) downloads updates if available, and 3) restarts the server. Ensure the paths in the script are correct, especially the following variables:
```bash
CHECKSUM_URL="https://www.factorio.com/download/sha256sums/"
LOCAL_CHECKSUM_FILE="factorio_sha256sums.txt"
INSTALLED_TAR="factorio-installed.tar.xz"
FACTORIO_DIR="factorio"
TMUX_SESSION="mysession"
FACTORIO_WINDOW="factorio"
```

4. Create and Configure tmux-session.service
    - This service will start the tmux session automatically at boot. In the tmux-session.service file, make sure to update <your_directory> in ExecStart to point to the actual path where start_tmux.sh resides.

5. Create and Configure factorio-updater.timer
    - The timer triggers the updater script on a set schedule. In this example, it’s set to check for updates every hour.

6. Create start_tmux.sh
    - This script initializes the tmux session and sets up the windows for the Factorio server.

7. Enable and Start the Systemd Services
    - Run the following commands to enable and start the necessary services:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable tmux-session.service
    sudo systemctl start tmux-session.service
    sudo systemctl enable factorio-updater.timer
    sudo systemctl start factorio-updater.timer
    ```
8. Logs and Troubleshooting
    - Logs for the tmux session are written to /tmp/tmux-session.log, while update logs are in factorio_root_folder logfile.log. Use these to troubleshoot any issues. 
    - If everything works fine, you should see a log like this written each hour:
    ```bash
    2024-10-25 11:00:00 - You are using the latest version (2.0.9). No update needed.
    2024-10-25 11:00:00 - Update process completed.
    2024-10-24 12:20:34 - A new version (factorio_linux_2.0.10.tar.xz) is available.
    2024-10-24 12:20:36 - Attempting to stop Factorio server...
    2024-10-24 12:20:36 - Sending /quit command to tmux session: mysession, window: factorio
    2024-10-24 12:20:36 - Command sent successfully.
    2024-10-24 12:20:41 - Factorio server has stopped.
    2024-10-24 12:20:41 - Updating Factorio server...
    2024-10-24 12:20:48 - Update process completed.
    ```
