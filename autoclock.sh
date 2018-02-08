#!/bin/bash

base="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The rig number (used for notifications only)
RIG=0

# The gpu numbers to overclock, 0-based. So gpu 0 is the first, etc.
# You can set start and end to the same number to overclock one gpu at a time.
GPU_START=0
GPU_END=6

# This is the power limit in WATTS, not %!
POWER_LIMIT=144

# How much should the clock increment by for each loop?
CORE_INCREMENT=1
MEM_INCREMENT=5

# The clock limits -- don't try overclocking higher than this.
STOP_CORE=300
STOP_MEM=2500

# This function is used to test if the gpu is stll mining. Grep for the mining
# process and return a count of the running threads.
function checkGpuMining() {
    threads="$(ps aux | grep "dev ${1}" | grep zm | wc -l)"
    # threads="$(ps aux | grep "devices ${1}" | grep bminer | wc -l)"
}

# THis funciton notifies upon failure. Be sure to update the discord url with
# your own, or replace the contents of this function to notify elsewhere --
# telegram, perchance?
function notifyFailure() {
    body=$(printf '{"channel": "#errors", "content": "RIG %s: GPU %s is dead!"}' "${1}" "${2}")
    curl -X POST --data-urlencode "payload_json=${body}" DISCORD_URL
}

# Script needs to run as sudo for nvidia-smi settings to take effect.
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

source "${base}/.gpu-start.sh"
source "${base}/.gpu-clocks.sh"

# Enable nvidia-smi settings so they are persistent the whole time the system is on.
nvidia-smi -pm 1

for gpu in $(seq ${GPU_START} ${GPU_END}); do
    echo "Setting power limit to ${POWER_LIMIT}W and power mode to 1."

    nvidia-smi -i ${gpu} -pl ${POWER_LIMIT} > "${base}/.gpu-log.log"
    nvidia-settings -a [gpu:${gpu}]/GpuPowerMizerMode=1 >> "${base}/.gpu-log.log"
done

function clockGpu() {
    parameter=${1}
    stop=${2}
    increment=${3}

    declare start="START_${parameter}"

    for gpu in $(seq ${GPU_START} ${GPU_END}); do
        declare gpu_clock_export="GPU_${gpu}_${parameter}"
        if [[ ! -z ${!gpu_clock_export} ]]; then
            echo "Setting GPU ${gpu} to ${parameter} ${!gpu_clock_export}"
            nvidia-settings -a [gpu:${gpu}]/${parameter}[3]=${!gpu_clock_export} >> "${base}/.gpu-log.log"
        fi
    done

    for clock in $(seq ${!start} ${increment} ${stop}); do
        changed=false

        for gpu in $(seq ${GPU_START} ${GPU_END}); do
            # This gpu has already been overclocked.
            declare gpu_clock_export="GPU_${gpu}_${parameter}"
            if [[ ! -z ${!gpu_clock_export} ]]; then
                continue
            fi

            echo "GPU ${gpu}: Clocking ${parameter} to ${clock}"

            changed=true
            nvidia-settings -a [gpu:${gpu}]/${parameter}[3]=${clock} >> "${base}/.gpu-log.log"

            checkGpuMining ${gpu}
            if [[ "0" == "${threads}" ]]; then
                # Let's be safe and remove 15 from the max clock.
                good_clock=$(expr ${clock} - 15)
                echo "export ${gpu_clock_export}=${good_clock}" >> "${base}/.gpu-clocks.sh"
                declare ${gpu_clock_export}=${good_clock}

                nvidia-settings -a [gpu:${gpu}]/${parameter}[3]=${good_clock} >> "${base}/.gpu-log.log"

                echo "************************************************************"
                echo "GPU ${gpu} thread is dead at clock speed ${clock}! Using ${good_clock}."
                echo "************************************************************"

                notifyFailure ${RIG} ${gpu}
            fi

            echo "export START_${parameter}=${clock}" > "${base}/.gpu-start.sh"

            sleep 1
        done

        if [[ true == ${changed} ]]; then
            sleep 15
        fi
    done
}

clockGpu GPUMemoryTransferRateOffset ${STOP_MEM} ${MEM_INCREMENT}
clockGpu GPUGraphicsClockOffset ${STOP_CORE} ${CORE_INCREMENT}
