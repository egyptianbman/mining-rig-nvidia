#!/bin/bash

session_name="rig1"

base="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo bash -c "X :1&"

sudo su -c 'echo "performance" >/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
sudo su -c 'echo 2800000 > /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq'

# Use this to start one instance of the miner for all of the gpus
# if [ -z "$(tmux ls | grep ${session_name})" ]
# then
#     # Create the session, since it'll be first.
#     tmux new-session -s "${session_name}" -c ${base} -n gpu -d
#     tmux send-keys "mine" C-m

#     tmux split-window -h -c ${base}/
#     tmux send-keys "${base}/overclock.sh" C-m

#     tmux split-window -v -c ${base}/
#     tmux send-keys "${base}/fans.sh" C-m
# fi

# Use this to start one instance of the miner for each gpu
if [ -z "$(tmux ls | grep ${session_name})" ]
then
    # Create the session, since it'll be first.
    tmux new-session -s "${session_name}" -c ${base} -n gpu -d
    tmux send-keys "minedev 0" C-m

    # Create left and right
    tmux split-window -h -c ${base}/
    tmux send-keys "minedev 1" C-m

    tmux select-window -t 0
    tmux split-window -v -c ${base}/
    tmux send-keys "minedev 5" C-m

    tmux select-pane -t 0
    tmux split-window -v -c ${base}/
    tmux send-keys "minedev 4" C-m

    tmux select-pane -t 0
    tmux split-window -v -c ${base}/
    tmux send-keys "minedev 2" C-m

    tmux select-pane -t 3
    tmux split-window -v -t 3 -c ${base}/
    tmux send-keys "minedev 3" C-m

    tmux select-pane -t 2
    tmux split-window -v -t 2 -c ${base}/
    tmux send-keys "minedev 6" C-m

    tmux select-pane -t 6
    tmux split-window -v -t 6 -c ${base}/
    tmux send-keys "${base}/overclock.sh && ${base}/fans.sh" C-m

    # tmux split-window -v -t 6 -c ${base}/myshare
    # tmux send-keys "sudo ./myshare t1QRKvmE5pGXahcadDWmt4qPknwEkV5yUqQ" C-m
fi

# tmux attach
