#!/bin/bash

# Log all output
exec > /tmp/tmux-session.log 2>&1

# Create the tmux session with the first window (index 0)
tmux new-session -s mysession -n bash -d
tmux send-keys -t mysession:0 'cd ~' C-m

# Create the factorio window (index 1)
tmux new-window -t mysession:1 -n factorio
tmux send-keys -t mysession:1 'cd .../factorio_root_folder && ./start.sh' C-m

# Select the first window (bash)
tmux select-window -t mysession:0
