#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DEFAULT_REGIONS=("russia" "bucharest" "finland" "frankfurt" "madrid" "milan" "rotterdam" "stockholm" "warsaw")
TOTAL_DOMAINS=15000

if [[ -n "${1:-}" ]]; then
    regions=("$1")
else
    regions=("${DEFAULT_REGIONS[@]}")
fi

if pgrep dnsmasq > /dev/null; then
    echo -e "\n${GREEN}Перезапускаем dnsmasq...${NC}"
    pkill -SIGHUP dnsmasq
else
    echo -e "\n${RED}Куда же подевался наш dnsmasq?${NC}"
fi

resolve_domain() {
    local domain="$1"
    local region="$2"
    local directory="./regions/$region"

    mkdir -p "$directory"

    local ip
    ip=$(dig +short A "$domain" | grep -Ev "(warning|timed out|no servers|mismatch)")

    if [[ -n "$ip" ]]; then
        {
            echo "$domain: $ip" >> "$directory/$region-voice-resolved"
            echo "$domain" >> "$directory/$region-voice-domains"
            echo "$ip" >> "$directory/$region-voice-ip"
        }
    fi
}

export -f resolve_domain

ALL_IP_LIST="./voice_domains/discord-voice-ip-list"
ALL_DOMAINS_LIST="./voice_domains/discord-voice-domains-list"

: > "$ALL_IP_LIST"
: > "$ALL_DOMAINS_LIST"

for region in "${regions[@]}"; do
    echo -e "\n${CYAN}Генерируем домены региона: ${YELLOW}$region${NC}"
    directory="./regions/$region"

    if [[ -z "$directory" || "$directory" == "/" ]]; then
        echo -e "${RED}Чуть не потёрли корень, сворачиваемся${NC}"
        exit 1
    fi
    rm -rf "${directory:?}/"*

    start_time=$(date +%s)
    start_date=$(date '+%d.%m.%Y в %H:%M:%S')

    mapfile -t domains < <(seq 1 "$TOTAL_DOMAINS" | awk -v region="$region" '{print region $1 ".discord.gg"}')

    echo -e "${GREEN}Резолвим...${NC}"
    printf "%s\n" "${domains[@]}" | parallel --bar -j252 resolve_domain {} "$region"

    sort -u "$directory/$region-voice-ip" >> "$ALL_IP_LIST" 2>/dev/null || true
    sort -u "$directory/$region-voice-domains" >> "$ALL_DOMAINS_LIST" 2>/dev/null || true

    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    domains_resolved=$(wc -l < "$directory/$region-voice-resolved" 2>/dev/null || echo 0)

    echo -e "\n${GREEN}Успех для региона ${YELLOW}$region${GREEN}!${NC}"
    echo -e "${BLUE}Время запуска:${NC} ${MAGENTA}$start_date${NC}"
    echo -e "${BLUE}Время выполнения:${NC} ${MAGENTA}$(date -ud "@$execution_time" +'%H:%M:%S')${NC}"
    echo -e "${BLUE}Доменов зарезолвили:${NC} ${MAGENTA}$domains_resolved${NC}"
done

ip_count=$(wc -l < "$ALL_IP_LIST" 2>/dev/null || echo 0)
echo -e "\n${GREEN}Список \"${YELLOW}${BOLD}$ALL_IP_LIST${NC}${GREEN}\" обновлён, зарезолвили ${MAGENTA}$ip_count${GREEN} адрес(ов)${NC}\n"
