#!/bin/bash

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

check_dependency() {
    if ! command -v "$1" &>/dev/null; then
        log_error "Команда '$1' не найдена. Установите её и повторите попытку."
        exit 1
    fi
}

check_dependency dig
check_dependency parallel

DEFAULT_REGIONS=("russia" "bucharest" "finland" "frankfurt" "madrid" "milan" "rotterdam" "stockholm" "warsaw")
TOTAL_DOMAINS=15000
PARALLEL_JOBS="${PARALLEL_JOBS:-252}"

if [[ -n "${1:-}" ]]; then
    IFS=' ' read -r -a regions <<< "$1"
else
    regions=("${DEFAULT_REGIONS[@]}")
fi

ALL_IP_LIST="./voice_domains/discord-voice-ip-list"
ALL_DOMAINS_LIST="./voice_domains/discord-voice-domains-list"

if pgrep dnsmasq > /dev/null; then
    log_info "Перезапускаем dnsmasq..."
    pkill -SIGHUP dnsmasq
else
    log_warn "Куда же подевался наш dnsmasq?"
fi

resolve_domain() {
    local domain="$1"
    local region="$2"
    local directory="./regions/$region"
    
    mkdir -p "$directory"

    local ips
    ips=$(dig +short A "$domain" | grep -Ev "(warning|timed out|no servers|mismatch)")
    
    if [[ -n "$ips" ]]; then
        {
            echo "$domain: $ips" >> "$directory/${region}-voice-resolved"
            echo "$domain" >> "$directory/${region}-voice-domains"
            while IFS= read -r ip; do
                echo "$ip" >> "$directory/${region}-voice-ip"
            done <<< "$ips"
        }
    fi
}

export -f resolve_domain
export RED GREEN YELLOW BLUE MAGENTA CYAN BOLD NC
export TOTAL_DOMAINS

: > "$ALL_IP_LIST"
: > "$ALL_DOMAINS_LIST"

for region in "${regions[@]}"; do
    line_skip
    log_info "Генерируем домены региона: ${YELLOW}$region${NC}"
    local_directory="./regions/$region"

    if [[ -z "$local_directory" || "$local_directory" == "/" ]]; then
        log_error "Чуть не потёрли корень, сворачиваемся"
        exit 1
    fi

    rm -rf "${local_directory:?}/"*
    
    start_time=$(date +%s)
    start_date=$(date '+%d.%m.%Y в %H:%M:%S')

    mapfile -t domains < <(seq 1 "$TOTAL_DOMAINS" | awk -v region="$region" '{print region $1 ".discord.gg"}')
    log_info "Резолвим домены региона $region..."
    printf "%s\n" "${domains[@]}" | parallel --bar -j"$PARALLEL_JOBS" resolve_domain {} "$region"

    if [[ -f "$local_directory/${region}-voice-ip" ]]; then
        sort -u "$local_directory/${region}-voice-ip" >> "$ALL_IP_LIST" 2>/dev/null || true
    fi
    if [[ -f "$local_directory/${region}-voice-domains" ]]; then
        sort -u "$local_directory/${region}-voice-domains" >> "$ALL_DOMAINS_LIST" 2>/dev/null || true
    fi

    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    domains_resolved=$(wc -l < "$local_directory/${region}-voice-resolved" 2>/dev/null || echo 0)

    log_info "Время запуска: ${MAGENTA}$start_date${NC}"
    log_info "Время выполнения: ${MAGENTA}$(date -ud "@$execution_time" +'%H:%M:%S')${NC}"
    log_info "Доменов зарезолвили: ${MAGENTA}$domains_resolved${NC}"
done

ip_count=$(wc -l < "$ALL_IP_LIST" 2>/dev/null || echo 0)

    line_skip
    log_success "Обновлён список \"${YELLOW}${BOLD}$ALL_IP_LIST${NC}\""
    log_success "Всего адресов зарезолвили: ${MAGENTA}$ip_count${NC}"
