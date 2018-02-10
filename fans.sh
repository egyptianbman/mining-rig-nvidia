#!/bin/bash

# Script needs to run as sudo for nvidia-smi settings to take effect.
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

set_speed () {
    echo "Gpu ${1} to ${2}% ${3}C"
    nvidia-settings -a "[gpu:${1}]/GPUFanControlState=1" -a "[fan:${1}]/GPUTargetFanSpeed=${2}" > /dev/null
}

reset_speed () {
    echo "Gpu ${1} to auto ${2}C"
    nvidia-settings -a "[gpu:${1}]/GPUFanControlState=0" > /dev/null
}

while true; do
    for gpu in 0 1 2 3 4 5 6; do
        current_temp=`nvidia-settings -t -q [GPU:${gpu}]/GPUCoreTemp`

        if [[ "$current_temp" -gt "75" ]]; then
            set_speed ${gpu} 100 ${current_temp}
        elif [[ "$current_temp" -gt "72" ]]; then
            speed="$(echo "${current_temp} * 1.26" | bc)"
            set_speed ${gpu} $(printf '%.*f\n' 0 ${speed}) ${current_temp}
        elif [[ "$current_temp" -gt "68" ]]; then
            speed="$(echo "${current_temp} * 1.1" | bc)"
            set_speed ${gpu} $(printf '%.*f\n' 0 ${speed}) ${current_temp}
        elif [[ "$current_temp" -gt "64" ]]; then
            speed="$(echo "${current_temp} * .9" | bc)"
            set_speed ${gpu} $(printf '%.*f\n' 0 ${speed}) ${current_temp}
        else
            reset_speed ${gpu} ${current_temp}
        fi
    done
    sleep 30
    echo '                           '
    echo '---------------------------'
done
