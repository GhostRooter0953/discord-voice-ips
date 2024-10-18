#!/usr/bin/env bash

discord_ips="$(wget -O- https://github.com/GhostRooter0953/discord-voice-ips/raw/refs/heads/master/amnezia/amnezia-discord-domains.json 2>/dev/null | jq -r 'map(select(.ip != "")) | map(.ip) | join(",")')"
sudo sed -i "/# Discord/{n;s|^AllowedIPs = .*|AllowedIPs = $discord_ips|}" "$CONFIG_PATH"

discord_voice_ips="$(wget -O- https://github.com/GhostRooter0953/discord-voice-ips/raw/refs/heads/master/amnezia/amnezia-voice-ip.json 2>/dev/null | jq -r 'map(select(.ip != "")) | map(.ip) | join(",")')"
sudo sed -i "/# Discord\ Voice/{n;s|^AllowedIPs = .*|AllowedIPs = $discord_voice_ips|}" "$CONFIG_PATH"
