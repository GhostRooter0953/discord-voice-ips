#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

line_skip()   { echo -e ". . ."; }
log_info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

BASE_DIR="$(cd "$(dirname "$0")" && pwd)/main_domains"
DOMAIN_LIST_FILE="$BASE_DIR/discord-main-domains-list"
IP_LIST_FILE="$BASE_DIR/discord-main-ip-list"
JSON_OUTPUT_FILE="$(cd "$(dirname "$0")" && pwd)/amnezia/amnezia-discord-domains.json"
PROGRESS_BAR_LENGTH=50

mkdir -p "$BASE_DIR"
mkdir -p "$(dirname "$JSON_OUTPUT_FILE")"

log_info "Очистка устаревших списков..."
: > "$IP_LIST_FILE"
: > "$JSON_OUTPUT_FILE"
echo "[" > "$JSON_OUTPUT_FILE"
first_entry=true

if pgrep dnsmasq > /dev/null 2>&1; then
    log_info "Перезапускаем dnsmasq..."
    pkill -SIGHUP dnsmasq
else
    log_warn "А куда же подевался наш dnsmasq?"
fi

if [[ ! -f "$DOMAIN_LIST_FILE" ]]; then
    log_error "Файл доменных имен ${YELLOW}$DOMAIN_LIST_FILE${RED} не найден!"
    exit 1
fi

total_domains=$(grep -cve '^\s*$' "$DOMAIN_LIST_FILE")
if [[ "$total_domains" -eq 0 ]]; then
    log_error "Файл ${YELLOW}$DOMAIN_LIST_FILE${RED} пустой. Нечего резолвить."
    exit 0
fi

log_info "Начинаем резолвинг доменов Discord..."

update_progress_bar() {
    local percent=$1
    local filled_length=$(( (PROGRESS_BAR_LENGTH * percent) / 100 ))
    local empty_length=$(( PROGRESS_BAR_LENGTH - filled_length ))
    local bar
    bar=$(printf "%${filled_length}s" | tr ' ' '#')
    bar+=$(printf "%${empty_length}s" | tr ' ' '-')
    printf "\r${CYAN}[INFO]${NC} Резолвим... [%s] %d%%${NC}" "$bar" "$percent"
}

resolve_to_ip() {
    local domain
    domain=$(echo "$1" | tr -d '\r')
    local output
    output=$(dig +short "$domain" A 2>/dev/null | tr -d '\r')
    if [[ -z "$output" ]]; then
        echo ""
        return 1
    fi
    local resolved_ips=()
    while IFS= read -r line; do
        line=$(echo "$line" | tr -d '\r')
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

mapfile -t domain_array < <(tr -d '\r' < "$DOMAIN_LIST_FILE")
count=0
failed_domains=()

for domain in "${domain_array[@]}"; do
    domain=$(echo "$domain" | tr -d '\r' | xargs)
    [[ -z "$domain" ]] && continue

    if ip_list=$(resolve_to_ip "$domain"); then
        if [[ -n "$ip_list" ]]; then
            while IFS= read -r ip_entry; do
                ip_entry=$(echo "$ip_entry" | tr -d '\r' | xargs)
                [[ -n "$ip_entry" ]] && echo "$ip_entry" >> "$IP_LIST_FILE"
            done <<< "$ip_list"
            ip=$(echo "$ip_list" | head -n1)
        else
            ip=""
            failed_domains+=("$domain")
        fi
    else
        ip=""
        failed_domains+=("$domain")
    fi

    json_entry=$(jq -c -n --arg hostname "$domain" --arg ip "$ip" \
        '{hostname: $hostname, ip: $ip}')
    if $first_entry; then
        first_entry=false
    else
        echo "," >> "$JSON_OUTPUT_FILE"
    fi
    echo "  $json_entry" >> "$JSON_OUTPUT_FILE"

    count=$((count + 1))
    percent=$(( (count * 100) / total_domains ))
    update_progress_bar "$percent"
done
echo
line_skip
log_success "Резолвинг завершён"
sort -u "$IP_LIST_FILE" -o "$IP_LIST_FILE"
echo "]" >> "$JSON_OUTPUT_FILE"

log_success "Результаты сохранены в файлы:"
echo -e " - $IP_LIST_FILE"
echo -e " - $JSON_OUTPUT_FILE"
line_skip
if [[ ${#failed_domains[@]} -gt 0 ]]; then
log_error "Не удалось зарезолвить следующие домены:"
    for d in "${failed_domains[@]}"; do
        echo -e " - ${RED}$d${NC}"
    done
else
    log_success "Все домены успешно зарезолвлены."
fi
