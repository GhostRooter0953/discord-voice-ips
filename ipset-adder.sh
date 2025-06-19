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
line_select() { echo -e "${BLUE}[SELECT]${NC} $*"; }
log_info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

generate_ipset_list() {
    local ip_file="$1"
    local ipset_file="$2"
    local ipset_name="$3"
    if [[ -f "$ip_file" ]]; then
        log_success "Сгенерирован список из ${YELLOW}$ip_file${NC}"
        : > "$ipset_file"
        while IFS= read -r ip; do
            [[ -z "$ip" ]] && continue
            echo "add $ipset_name $ip timeout 0 -exist" >> "$ipset_file"
        done < "$ip_file"
    else
        log_warn "Генерация списка из ${YELLOW}$ip_file${NC} ${RED}невозможна${NC}, файл не найден – ${GREEN}пропускаем${NC}"
    fi
}

update_ipset_from_files() {
    local ipset_name="$1"
    shift
    local ipset_files=("$@")
    local tmp_ipset_restore_file
    tmp_ipset_restore_file=$(mktemp)
    declare -A existing_ips_array

    if ipset list "$ipset_name" &>/dev/null; then
        existing_ips=$(ipset list "$ipset_name" | sed -n '/^Members:/,$p' | tail -n +2 | awk '{ print $1 }' | sort)
        while IFS= read -r ip; do
            [[ -n "$ip" ]] && existing_ips_array["$ip"]=1
        done <<< "$existing_ips"
    fi

    for ipset_file in "${ipset_files[@]}"; do
        if [[ -f "$ipset_file" ]]; then
            while IFS= read -r line; do
                ip=$(echo "$line" | awk '{print $3}')
                ip="${ip// }"
                [[ -z "$ip" ]] && continue
                if [[ -z "${existing_ips_array["$ip"]-}" ]]; then
                    echo "add $ipset_name $ip timeout 0 -exist" >> "$tmp_ipset_restore_file"
                    existing_ips_array["$ip"]=1
                fi
            done < "$ipset_file"
        else
            log_warn "Генерация списка из ${YELLOW}$ip_list_file${NC} ${RED}невозможна${NC}, файл не найден – пропускаем"
        fi
    done

    if [[ -s "$tmp_ipset_restore_file" ]]; then
        ipset restore < "$tmp_ipset_restore_file"
        local count
        count=$(wc -l < "$tmp_ipset_restore_file")
        log_success "Загружено ${GREEN}$count${NC} IP адрес(ов) в IPset лист: ${YELLOW}$ipset_name${NC}"
    else
        log_warn "Нет новых IP адресов для добавления в IPset лист: ${YELLOW}$ipset_name${NC}"
    fi

    rm -f "$tmp_ipset_restore_file"
}

prepare_ipset_files() {
    local ipset_name="$1"
    generate_ipset_list "$main_ip_list_file" "$main_ipset_list_file" "$ipset_name"
    generate_ipset_list "$voice_ip_list_file" "$voice_ipset_list_file" "$ipset_name"
    for region_dir in ./regions/*; do
        if [[ -d "$region_dir" ]]; then
            local region
            region=$(basename "$region_dir")
            local ip_list_file="$region_dir/${region}-voice-ip"
            local ipset_file="$region_dir/${region}-voice-ipset"
            generate_ipset_list "$ip_list_file" "$ipset_file" "$ipset_name"
        fi
    done
}

ensure_ipset_exists() {
    local ipset_name="$1"
    if ! ipset list "$ipset_name" &>/dev/null; then
        ipset create "$ipset_name" hash:ip timeout 86400
        log_success "Создан IPset лист: ${YELLOW}$ipset_name${NC}"
    else
        log_info "Используем существующий IPset лист: ${YELLOW}$ipset_name${NC}"
    fi
}

main_ip_list_file="./main_domains/discord-main-ip-list"
main_ipset_list_file="./main_domains/discord-main-ipset-list"
voice_ip_list_file="./voice_domains/discord-voice-ip-list"
voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

if [[ "$#" -gt 0 ]]; then
    if [[ "$1" == "noipset" ]]; then
        log_info "Запущен режим ${BLUE}noipset${NC}"
        ipset_name="unblock"
        log_info "Используем IPset лист: ${YELLOW}$ipset_name${NC}"
        prepare_ipset_files "$ipset_name"
        exit 0
    else
        ipset_name="$1"
        log_info "Запущен режим ${BLUE}list${NC}"
        prepare_ipset_files "$ipset_name"
        ensure_ipset_exists "$ipset_name"
        selected_ipset_files=("$main_ipset_list_file" "$voice_ipset_list_file")
        update_ipset_from_files "$ipset_name" "${selected_ipset_files[@]}"
        exit 0
    fi
else
    existing_ipsets=$(ipset list -n | grep -vE '(^_NDM|^_UPNP)' || true)
    if [[ -n "$existing_ipsets" ]]; then
        mapfile -t ipset_list <<< "$existing_ipsets"
        log_info "Подготовка к генерации..."
        log_info "Существующие IPset листы:"
        for i in "${!ipset_list[@]}"; do
            line_select "$((i+1)). ${YELLOW}${ipset_list[$i]}${NC}"
        done
        line_select "0. Создать новый IPset лист"

        while true; do
            read -rp "Выбери номер IPset листа в который будет выполнен импорт: " ipset_option
            if [[ "$ipset_option" =~ ^[0-9]+$ ]]; then
                if [[ "$ipset_option" -eq 0 ]]; then
                    read -rp "Введите имя для IPset листа: " user_ipset_name
                    ipset_name=${user_ipset_name:-unblock}
                    break
                elif (( ipset_option >= 1 && ipset_option <= ${#ipset_list[@]} )); then
                    ipset_name="${ipset_list[$((ipset_option-1))]}"
                    break
                else
                    log_error "Неправильно. Попробуй ещё раз."
                fi
            else
                log_warn "Что происходит?"
            fi
        done
    else
        log_info "Подготовка к генерации..."
        log_warn "IPset листы отсутствуют!"
        read -rp "Введите имя для нового IPset листа: " user_ipset_name
        ipset_name=${user_ipset_name:-unblock}
    fi

    prepare_ipset_files "$ipset_name"
    ensure_ipset_exists "$ipset_name"

    log_info "Какие списки импортируем в IPset:"
    line_select "1. Список с основными серверами"
    line_select "2. Список с основными и всеми голосовыми серверами${NC}"
    line_select "3. Список с основными и конкретными голосовыми серверами${NC}"

    while true; do
        read -rp "Выбери вариант: " list_option
        if [[ "$list_option" =~ ^[1-3]$ ]]; then
            break
        else
            log_error "Неправильно. Попробуй ещё раз."
        fi
    done
    
    selected_ipset_files=("$main_ipset_list_file")
    case "$list_option" in
        1)
            ;;
        2)
            selected_ipset_files+=("$voice_ipset_list_file")
            ;;
        3)
            regions=()
            for region_dir in ./regions/*; do
                if [[ -d "$region_dir" ]]; then
                    regions+=("$(basename "$region_dir")")
                fi
            done
            selected_regions=()
            while true; do
                echo -e "${GREEN}0. Далее${NC}"
                for i in "${!regions[@]}"; do
                    region="${regions[$i]}"
                    if [[ " ${selected_regions[*]} " =~ " $region " ]]; then
                        echo -e "$((i+1)). ${MAGENTA}$region ${GREEN}- Уже выбран${NC}"
                    else
                        echo -e "$((i+1)). ${MAGENTA}$region${NC}"
                    fi
                done
                read -rp "Выбери регион: " region_option
                if [[ "$region_option" == "0" ]]; then
                    break
                elif [[ "$region_option" =~ ^[0-9]+$ ]] && (( region_option >= 1 && region_option <= ${#regions[@]} )); then
                    region="${regions[$((region_option-1))]}"
                    if [[ ! " ${selected_regions[*]} " =~ " $region " ]]; then
                        selected_regions+=("$region")
                    else
                        log_info "Регион ${MAGENTA}$region${GREEN} уже выбран"
                    fi
                else
                    log_error "Неправильно. Попробуй ещё раз."
                fi
            done
            for region in "${selected_regions[@]}"; do
                ipset_file="./regions/$region/${region}-voice-ipset"
                if [[ -f "$ipset_file" ]]; then
                    selected_ipset_files+=("$ipset_file")
                else
                    log_warn "Список для региона ${MAGENTA}$region${NC} не найден – пропускаем"
                fi
            done
            ;;
    esac

    update_ipset_from_files "$ipset_name" "${selected_ipset_files[@]}"
fi
