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

BASE_DIR="$(cd "$(dirname "$0")" && pwd)/main_domains"
DOMAIN_LIST_FILE="$BASE_DIR/discord-main-domains-list"
IP_LIST_FILE="$BASE_DIR/discord-main-ip-list"
JSON_OUTPUT_FILE="$(cd "$(dirname "$0")" && pwd)/amnezia/amnezia-discord-domains.json"

mkdir -p "$BASE_DIR"
mkdir -p "$(dirname "$JSON_OUTPUT_FILE")"

echo -e "\n${CYAN}Чистим устаревшие списки...${NC}"
: > "$IP_LIST_FILE"
: > "$JSON_OUTPUT_FILE"

echo "[" > "$JSON_OUTPUT_FILE"
first_entry=true

if pgrep dnsmasq > /dev/null 2>&1; then
    echo -e "${CYAN}Перезапускаем dnsmasq...${NC}"
    pkill -SIGHUP dnsmasq
else
    echo -e " - ${RED}А куда же подевался наш dnsmasq?${NC}"
fi

if [[ ! -f "$DOMAIN_LIST_FILE" ]]; then
    echo -e "${RED}Файл ${YELLOW}$DOMAIN_LIST_FILE${RED} не найден!${NC}"
    exit 1
fi

total_domains=$(grep -cve '^\s*$' "$DOMAIN_LIST_FILE")
if [[ "$total_domains" -eq 0 ]]; then
    echo -e "${YELLOW}Файл $DOMAIN_LIST_FILE пустой. Нечего резолвить.${NC}"
    exit 0
fi

echo -e "${CYAN}Начинаем резолвинг IP основных серверов Discord...${NC}"

count=0
failed_domains=()
progress_bar_length=50

mapfile -t domain_array < "$DOMAIN_LIST_FILE"

resolve_to_ip() {
    local domain="$1"
    local resolved_ips=()
    local output
    output=$(dig +short "$domain" A 2>/dev/null)

    if [[ -z "$output" ]]; then
        echo ""
        return 1
    fi

    while read -r line; do
        if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            resolved_ips+=("$line")
        else
            if new_ips=$(resolve_to_ip "$line"); then
                resolved_ips+=($new_ips)
            fi
        fi
    done <<< "$output"

    echo "${resolved_ips[@]}" | tr ' ' '\n' | sort -u
    return 0
}

for domain_name in "${domain_array[@]}"; do
    domain_name=$(echo "$domain_name" | xargs)

    if [[ -z "$domain_name" ]]; then
        continue
    fi

    if ip_list=$(resolve_to_ip "$domain_name"); then
        if [[ -n "$ip_list" ]]; then
            ip=$(echo "$ip_list" | head -n1)
            while IFS= read -r ip_entry; do
                ip_entry=$(echo "$ip_entry" | xargs)
                if [[ -n "$ip_entry" ]]; then
                    echo "$ip_entry" >> "$IP_LIST_FILE"
                fi
            done <<< "$ip_list"
        else
            ip=""
            failed_domains+=("$domain_name")
        fi
    else
        ip=""
        failed_domains+=("$domain_name")
    fi

    json_entry=$(jq -c -n --arg hostname "$domain_name" --arg ip "$ip" '{hostname: $hostname, ip: $ip}')

    if $first_entry; then
        first_entry=false
    else
        echo "," >> "$JSON_OUTPUT_FILE"
    fi
    echo "  $json_entry" >> "$JSON_OUTPUT_FILE"

    count=$((count + 1))

    percent=$(( (count * 100) / total_domains ))

    filled_length=$(( (progress_bar_length * percent) / 100 ))
    empty_length=$(( progress_bar_length - filled_length ))

    progress_bar=$(printf "%${filled_length}s" | tr ' ' '#')
    progress_bar+=$(printf "%${empty_length}s" | tr ' ' '-')

    printf "\r${CYAN}Резолвим... [${progress_bar}] %d%%${NC}" "$percent"
done

echo -e "\n${CYAN}Резолвинг завершён.${NC}"
sort -u "$IP_LIST_FILE" -o "$IP_LIST_FILE"
echo "]" >> "$JSON_OUTPUT_FILE"
echo -e "\nIP адреса сохранены в файлы:"
echo -e " - ${YELLOW}$IP_LIST_FILE${NC}"
echo -e " - ${YELLOW}$JSON_OUTPUT_FILE${NC}"

if [[ ${#failed_domains[@]} -gt 0 ]]; then
    echo -e "\n${NC}Не удалось резолвить следующие домены:${NC}"
    for failed_domain in "${failed_domains[@]}"; do
        echo -e " - ${RED}$failed_domain${NC}"
    done
else
    echo -e "${GREEN}Все домены успешно резолвлены${NC}"
fi
