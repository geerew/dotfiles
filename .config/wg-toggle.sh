#!/usr/bin/env bash

# $ sudo pacman -Syu kdialog
# $ sudo visudo -f /etc/sudoers.d/wireguard
# USERNAME ALL=(root) NOPASSWD: \
#    /usr/bin/wg-quick up se-mma-wg-004, \
#    /usr/bin/wg-quick down se-mma-wg-004

IF="se-mma-wg-004"

connected_interface=$(networkctl | grep -P "\d+ .* wireguard routable" -o | cut -d" " -f2)

# Figure out current state & desired action
if [[ $connected_interface ]]; then 
    ACTION="down"
    QUESTION="WireGuard is up. Disable it?"
else
    ACTION="up"
    QUESTION="WireGuard is down. Enable it?"
fi

# Ask the user via KDE’s native dialog
if kdialog --yesno "$QUESTION"; then
    sudo wg-quick "$ACTION" "$IF"
    if [[ $? -eq 0 ]]; then
      kdialog --passivepopup "WireGuard ${ACTION} successful" 2
    else
      kdialog --error "Failed to ${ACTION} WireGuard"
    fi
fi
