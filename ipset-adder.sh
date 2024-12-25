#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

generate_ipset_list() {
    local ip_file="$1"
    local ipset_file="$2"
    local ipset_name="$3"
    if [[ -f "$ip_file" ]]; then
        echo -e " - ${YELLOW}$ip_file${NC}"
        : > "$ipset_file"
        while IFS= read -r ip; do
            echo "add $ipset_name $ip -exist" >> "$ipset_file"
        done < "$ip_file"
    else
        echo -e "${RED}IP файл $ip_file не найден${NC}"
    fi
}

mode="${1:-}"

if [[ "$mode" == "auto" ]]; then
    ipset_name="unblock"
    echo -e "\n${GREEN}Запущен режим ${YELLOW}auto${GREEN}. Используем IPset лист: ${YELLOW}${ipset_name}${NC}"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

    echo -e "${GREEN}Генерируем списки в формате IPset из:${NC}"

    generate_ipset_list "$main_ip_list_file" "$main_ipset_list_file" "$ipset_name"
    generate_ipset_list "$voice_ip_list_file" "$voice_ipset_list_file" "$ipset_name"

    if ! ipset list "$ipset_name" > /dev/null 2>&1; then
        ipset create "$ipset_name" hash:ip
        echo -e "${GREEN}IPset лист ${YELLOW}$ipset_name${GREEN} создан${NC}"
    else
        echo -e "${GREEN}Работаем дальше...${NC}"
    fi

    existing_ips=$(ipset list "$ipset_name" | sed -n '/^Members:/,$p' | tail -n +2 | awk '{ print $1 }' | sort)

    declare -A existing_ips_array
    while IFS= read -r ip; do
        ip="${ip// }"
        if [[ -n "$ip" ]]; then
            existing_ips_array["$ip"]=1
        fi
    done <<< "$existing_ips"

    selected_ipset_files=("$main_ipset_list_file" "$voice_ipset_list_file")

    tmp_ipset_restore_file=$(mktemp)

    for ipset_file in "${selected_ipset_files[@]}"; do
        while IFS= read -r line; do
            ip=$(echo "$line" | awk '{print $3}')
            ip="${ip// }"
            if [[ -z "$ip" ]]; then
                continue
            fi
            if [[ -z "${existing_ips_array["$ip"]-}" ]]; then
                echo "add $ipset_name $ip -exist" >> "$tmp_ipset_restore_file"
                existing_ips_array["$ip"]=1
            fi
        done < "$ipset_file"
    done

    if [[ -s "$tmp_ipset_restore_file" ]]; then
        ipset restore < "$tmp_ipset_restore_file"
        count=$(wc -l < "$tmp_ipset_restore_file")
        echo -e "${GREEN}Загружено ${YELLOW}$count${GREEN} IP адреса(ов) в IPset лист ${YELLOW}$ipset_name${NC}"
    else
        echo -e "${RED}Нет новых IP адресов для добавления в IPset${NC}"
    fi

    rm -f "$tmp_ipset_restore_file"

    exit 0

elif [[ "$mode" == "list" ]]; then
    ipset_name="${2:-}"

    if [[ -z "$ipset_name" ]]; then
        echo -e "${RED}Имя IPset листа не указано. Выполни: ./ipset-adder.sh list <имя_листа>${NC}"
        exit 1
    fi

    echo -e "\n${GREEN}Запущен режим ${YELLOW}list${GREEN}. Используем IPset лист: ${YELLOW}${ipset_name}${NC}"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

    echo -e "${GREEN}Генерируем списки в формате IPset из:${NC}"

    generate_ipset_list "$main_ip_list_file" "$main_ipset_list_file" "$ipset_name"
    generate_ipset_list "$voice_ip_list_file" "$voice_ipset_list_file" "$ipset_name"

    if ! ipset list "$ipset_name" > /dev/null 2>&1; then
        ipset create "$ipset_name" hash:ip
        echo -e "${GREEN}IPset лист ${YELLOW}$ipset_name${GREEN} создан${NC}"
    else
        echo -e "${GREEN}Работаем дальше...${NC}"
    fi

    existing_ips=$(ipset list "$ipset_name" | sed -n '/^Members:/,$p' | tail -n +2 | awk '{ print $1 }' | sort)

    declare -A existing_ips_array
    while IFS= read -r ip; do
        ip="${ip// }"
        if [[ -n "$ip" ]]; then
            existing_ips_array["$ip"]=1
        fi
    done <<< "$existing_ips"

    selected_ipset_files=("$main_ipset_list_file" "$voice_ipset_list_file")

    tmp_ipset_restore_file=$(mktemp)

    for ipset_file in "${selected_ipset_files[@]}"; do
        while IFS= read -r line; do
            ip=$(echo "$line" | awk '{print $3}')
            ip="${ip// }"
            if [[ -z "$ip" ]]; then
                continue
            fi
            if [[ -z "${existing_ips_array["$ip"]-}" ]]; then
                echo "add $ipset_name $ip -exist" >> "$tmp_ipset_restore_file"
                existing_ips_array["$ip"]=1
            fi
        done < "$ipset_file"
    done

    if [[ -s "$tmp_ipset_restore_file" ]]; then
        ipset restore < "$tmp_ipset_restore_file"
        count=$(wc -l < "$tmp_ipset_restore_file")
        echo -e "${GREEN}Загружено ${YELLOW}$count${GREEN} IP адреса(ов) в IPset лист ${YELLOW}$ipset_name${NC}"
    else
        echo -e "${RED}Нет новых IP адресов для добавления в IPset${NC}"
    fi

    rm -f "$tmp_ipset_restore_file"

    exit 0

elif [[ "$mode" == "noipset" ]]; then
    echo -e "\n${GREEN}Запущен режим ${YELLOW}noipset${NC}"

    ipset_name="unblock"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

    echo -e "${GREEN}Генерируем списки в формате IPset из:${NC}"

    generate_ipset_list "$main_ip_list_file" "$main_ipset_list_file" "$ipset_name"
    generate_ipset_list "$voice_ip_list_file" "$voice_ipset_list_file" "$ipset_name"

    for region_dir in ./regions/*; do
        if [[ -d "$region_dir" ]]; then
            region=$(basename "$region_dir")
            ip_list_file="$region_dir/${region}-voice-ip"
            ipset_file="$region_dir/${region}-voice-ipset"
            generate_ipset_list "$ip_list_file" "$ipset_file" "$ipset_name"
        fi
    done
    exit 0
else
    existing_ipsets=$(ipset list -n | grep -vE '(^_NDM|^_UPNP)' || true)

    if [[ -n "$existing_ipsets" ]]; then
        mapfile -t ipset_list <<< "$existing_ipsets"

        echo -e "${GREEN}\nПодготовка к генерации...${NC}"
        echo -e "${GREEN}Существующие IPset листы:${NC}"
        for i in "${!ipset_list[@]}"; do
            echo -e "${YELLOW}$((i+1)). ${ipset_list[$i]}${NC}"
        done
        echo -e "${YELLOW}0. Создать новый IPset лист${NC}"

        while true; do
            read -rp "Выбери в какой IPset лист выполняем импорт: " ipset_option
            if [[ "$ipset_option" =~ ^[0-9]+$ ]]; then
                if [[ "$ipset_option" -eq 0 ]]; then
                    read -rp "Введите имя для IPset листа: " user_ipset_name
                    ipset_name=${user_ipset_name:-unblock}
                    break
                elif (( ipset_option >= 1 && ipset_option <= ${#ipset_list[@]} )); then
                    ipset_name="${ipset_list[$((ipset_option-1))]}"
                    break
                else
                    echo -e "${RED}Неверный номер варианта. Попробуйте снова${NC}"
                fi
            else
                echo -e "${YELLOW}Пожалуйста, введите номер варианта${NC}"
            fi
        done
    else
        echo -e "${GREEN}\nПодготовка к генерации...${NC}"
        echo -e "${RED}IPset листы отсутствуют!${NC}"
        read -rp "Введите имя для нового IPset листа: " user_ipset_name
        ipset_name=${user_ipset_name:-unblock}
    fi

    echo -e "${GREEN}Используем IPset лист: ${YELLOW}${ipset_name}${NC}"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

    echo -e "${GREEN}Генерируем списки в формате IPset из:${NC}"

    generate_ipset_list "$main_ip_list_file" "$main_ipset_list_file" "$ipset_name"
    generate_ipset_list "$voice_ip_list_file" "$voice_ipset_list_file" "$ipset_name"

    for region_dir in ./regions/*; do
        if [[ -d "$region_dir" ]]; then
            region=$(basename "$region_dir")
            ip_list_file="$region_dir/${region}-voice-ip"
            ipset_file="$region_dir/${region}-voice-ipset"
            generate_ipset_list "$ip_list_file" "$ipset_file" "$ipset_name"
        fi
    done

    if ! ipset list "$ipset_name" > /dev/null 2>&1; then
        ipset create "$ipset_name" hash:ip
        echo -e "${GREEN}IPset лист ${YELLOW}$ipset_name${GREEN} создан${NC}"
    else
        echo -e "${GREEN}Работаем дальше...${NC}"
    fi

    existing_ips=$(ipset list "$ipset_name" | sed -n '/^Members:/,$p' | tail -n +2 | awk '{ print $1 }' | sort)

    declare -A existing_ips_array
    while IFS= read -r ip; do
        ip="${ip// }"
        if [[ -n "$ip" ]]; then
            existing_ips_array["$ip"]=1
        fi
    done <<< "$existing_ips"

    echo -e "${GREEN}Выбери списки для загрузки:${NC}"
    echo -e "${YELLOW}1. Список с основными серверами${NC}"
    echo -e "${YELLOW}2. Список с основными и всеми голосовыми серверами${NC}"
    echo -e "${YELLOW}3. Список с основными и конкретными голосовыми серверами по регионам${NC}"

    while true; do
        read -rp "Введите номер варианта (1-3): " list_option
        if [[ "$list_option" =~ ^[1-3]$ ]]; then
            break
        else
            echo -e "${RED}Ты ошибся. Давай снова${NC}"
        fi
    done

    selected_ipset_files=("$main_ipset_list_file")

    case "$list_option" in
        1)
            # Вариант 1: только основные серверы
            ;;
        2)
            # Вариант 2: основные серверы и все голосовые серверы
            selected_ipset_files+=("$voice_ipset_list_file")
            ;;
        3)
            # Вариант 3: основные серверы и выбранные регионы
            regions=()
            for region_dir in ./regions/*; do
                if [[ -d "$region_dir" ]]; then
                    region=$(basename "$region_dir")
                    regions+=("$region")
                fi
            done

            selected_regions=()
            while true; do
                echo -e "${YELLOW}0. Далее${NC}"
                for i in "${!regions[@]}"; do
                    region="${regions[$i]}"
                    if [[ " ${selected_regions[@]} " =~ " $region " ]]; then
                        echo -e "${YELLOW}$((i+1)). $region ${GREEN}- Уже выбран${NC}"
                    else
                        echo -e "${YELLOW}$((i+1)). $region${NC}"
                    fi
                done

                read -rp "Выбери номер региона: " region_option

                if [[ "$region_option" == "0" ]]; then
                    break
                elif [[ "$region_option" =~ ^[0-9]+$ ]] && (( region_option >= 1 && region_option <= ${#regions[@]} )); then
                    region="${regions[$((region_option-1))]}"
                    if [[ ! " ${selected_regions[@]} " =~ " $region " ]]; then
                        selected_regions+=("$region")
                    else
                        echo -e "${GREEN}Регион ${YELLOW}$region${GREEN} уже выбран${NC}"
                    fi
                else
                    echo -e "${RED}Похоже, что ты ошибся. Снова${NC}"
                fi
            done

            for region in "${selected_regions[@]}"; do
                ipset_file="./regions/$region/${region}-voice-ipset"
                if [[ -f "$ipset_file" ]]; then
                    selected_ipset_files+=("$ipset_file")
                else
                    echo -e "${RED}IPset файл для региона '$region' не найден${NC}"
                fi
            done
            ;;
    esac

    missing_files=()
    for file in "${selected_ipset_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${RED}Следующие файлы не найдены:${NC}"
        for file in "${missing_files[@]}"; do
            echo " - $file"
        done
        echo -e "${RED}Завершение скрипта${NC}"
        exit 1
    fi

    tmp_ipset_restore_file=$(mktemp)

    for ipset_file in "${selected_ipset_files[@]}"; do
        while IFS= read -r line; do
            ip=$(echo "$line" | awk '{print $3}')
            ip="${ip// }"
            if [[ -z "$ip" ]]; then
                continue
            fi
            if [[ -z "${existing_ips_array["$ip"]-}" ]]; then
                echo "add $ipset_name $ip -exist" >> "$tmp_ipset_restore_file"
                existing_ips_array["$ip"]=1
            fi
        done < "$ipset_file"
    done

    if [[ -s "$tmp_ipset_restore_file" ]]; then
        ipset restore < "$tmp_ipset_restore_file"
        count=$(wc -l < "$tmp_ipset_restore_file")
        echo -e "${GREEN}Загружено ${YELLOW}$count${GREEN} IP адреса(ов) в IPset лист ${YELLOW}$ipset_name${NC}"
    else
        echo -e "${RED}Нет новых IP адресов для добавления в IPset${NC}"
    fi

    rm -f "$tmp_ipset_restore_file"
fi
