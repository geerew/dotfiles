#!/usr/bin/env bash

connected_interface=$(networkctl | grep -P "\d+ .* wireguard routable" -o | cut -d" " -f2)

if [[ $connected_interface ]]; then 
    echo -e "%{F#00FF00}●%{F-}"
else 
    echo -e "%{F#FF0000}●%{F-}"
fi
