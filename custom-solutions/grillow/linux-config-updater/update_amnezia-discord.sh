#!/usr/bin/env bash

discord_ips="$(wget -O- https://github.com/GhostRooter0953/discord-voice-ips/raw/refs/heads/master/main_domains/discord-main-ip-list 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
sudo sed -i "/# Discord/{n;s|^AllowedIPs = .*|AllowedIPs = $discord_ips|}" "$CONFIG_PATH"

discord_voice_ips="$(wget -O- https://github.com/GhostRooter0953/discord-voice-ips/raw/refs/heads/master/voice_domains/discord-voice-ip-list 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
sudo sed -i "/# Discord\ Voice/{n;s|^AllowedIPs = .*|AllowedIPs = $discord_voice_ips|}" "$CONFIG_PATH"
