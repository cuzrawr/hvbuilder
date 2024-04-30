#!/bin/bash

# loading animation
function show_loading() {
    local chars="/-\|"
    local delay=0.1
    local count=0

    while true; do
        printf "%c\b" "${chars:$count:1}"
        ((count = (count + 1) % ${#chars}))
        sleep $delay
    done
}

# Run the loading animation function in the background
show_loading &
loading_pid=$!

#
sleep 10

# Terminate the loading animation
kill $loading_pid >/dev/null 2>&1
wait $loading_pid >/dev/null 2>&1
