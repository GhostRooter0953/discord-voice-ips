#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

confirm() {
    while true; do
        read -rp "$1 (Y/N): " yn
        case $yn in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) echo -e "${YELLOW}Пожалуйста, ответьте Y или N.${NC}" ;;
        esac
    done
}

generate_ipset_list() {
    local ip_file="$1"
    local ipset_file="$2"
    local ipset_name="$3"
    if [[ -f "$ip_file" ]]; then
        echo -e " - ${BLUE}Генерируем IPset список из файла ${YELLOW}$ip_file${NC}"
        : > "$ipset_file"
        while IFS= read -r ip; do
            echo "add $ipset_name $ip" >> "$ipset_file"
        done < "$ip_file"
    else
        echo -e "${RED}IP файл $ip_file не найден.${NC}"
    fi
}

mode="${1:-}"

if [[ "$mode" == "auto" ]]; then
    ipset_name="unblock"
    echo -e "${GREEN}Запущен режим 'auto'. Используем IPset список: '${ipset_name}'${NC}"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

    generate_ipset_list "$main_ip_list_file" "$main_ipset_list_file" "$ipset_name"
    generate_ipset_list "$voice_ip_list_file" "$voice_ipset_list_file" "$ipset_name"

    if ! sudo ipset list "$ipset_name" > /dev/null 2>&1; then
        sudo ipset create "$ipset_name" hash:ip
        echo -e "${GREEN}IPset список '$ipset_name' создан.${NC}"
    else
        echo -e "${GREEN}IPset список '$ipset_name' уже существует.${NC}"
    fi

    existing_ips=$(sudo ipset list "$ipset_name" | sed -n '/^Members:/,$p' | tail -n +2 | awk '{$1=$1};1' | sort)

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
                echo "add $ipset_name $ip" >> "$tmp_ipset_restore_file"
                existing_ips_array["$ip"]=1
            fi
        done < "$ipset_file"
    done

    if [[ -s "$tmp_ipset_restore_file" ]]; then
        sudo ipset restore < "$tmp_ipset_restore_file"
        count=$(wc -l < "$tmp_ipset_restore_file")
        echo -e "${GREEN}Загружено $count IP адреса(ов) в список '$ipset_name'.${NC}"
    else
        echo -e "${YELLOW}Нет новых IP адресов для добавления в IPset.${NC}"
    fi

    rm -f "$tmp_ipset_restore_file"

    exit 0
elif [[ "$mode" == "noipset" ]]; then
    echo -e "${GREEN}Запущен режим 'noipset'. Генерируем файлы списков и завершаем.${NC}"

    ipset_name="unblock"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

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

    echo -e "${GREEN}Все IPset списки сгенерированы и готовы к использованию вручную.${NC}"
    exit 0
else
    echo -e "${GREEN}Генерируем IPset списки...${NC}"
    read -rp "Введите имя для IPset списка (он будет создан, если таковой отсутствует): " user_ipset_name
    ipset_name=${user_ipset_name:-unblock}
    echo -e "${GREEN}Используем IPset список: '${ipset_name}'${NC}"

    main_ip_list_file="./main_domains/discord-main-ip-list"
    main_ipset_list_file="./main_domains/discord-main-ipset-list"
    voice_ip_list_file="./voice_domains/discord-voice-ip-list"
    voice_ipset_list_file="./voice_domains/discord-voice-ipset-list"

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

    if ! sudo ipset list "$ipset_name" > /dev/null 2>&1; then
        echo -e "${YELLOW}IPset список '$ipset_name' не найден. Создаем...${NC}"
        sudo ipset create "$ipset_name" hash:ip
        echo -e "${GREEN}IPset список '$ipset_name' создан.${NC}"
    else
        echo -e "${GREEN}IPset список '$ipset_name' уже существует.${NC}"
    fi

    existing_ips=$(sudo ipset list "$ipset_name" | sed -n '/^Members:/,$p' | tail -n +2 | awk '{$1=$1};1' | sort)

    declare -A existing_ips_array
    while IFS= read -r ip; do
        ip="${ip// }"
        if [[ -n "$ip" ]]; then
            existing_ips_array["$ip"]=1
        fi
    done <<< "$existing_ips"

    echo -e "${GREEN}Выберите списки для загрузки:${NC}"
    echo "1. Список с основными серверами"
    echo "2. Список с основными и всеми голосовыми серверами"
    echo "3. Список с основными и конкретными голосовыми серверами по регионам"

    while true; do
        read -rp "Введите номер варианта (1-3): " list_option
        if [[ "$list_option" =~ ^[1-3]$ ]]; then
            break
        else
            echo -e "${YELLOW}Ты ошибся. Давай снова.${NC}"
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
            # Получаем список регионов
            regions=()
            for region_dir in ./regions/*; do
                if [[ -d "$region_dir" ]]; then
                    region=$(basename "$region_dir")
                    regions+=("$region")
                fi
            done

            selected_regions=()
            while true; do
                echo -e "\nВыбери регион и введи его номер ниже"
                echo "0. ДАЛЕЕ"
                for i in "${!regions[@]}"; do
                    region="${regions[$i]}"
                    if [[ " ${selected_regions[@]} " =~ " $region " ]]; then
                        echo "$((i+1)). $region - УЖЕ ВЫБРАН"
                    else
                        echo "$((i+1)). $region"
                    fi
                done

                read -rp "Номер: " region_option

                if [[ "$region_option" == "0" ]]; then
                    break
                elif [[ "$region_option" =~ ^[0-9]+$ ]] && (( region_option >= 1 && region_option <= ${#regions[@]} )); then
                    region="${regions[$((region_option-1))]}"
                    if [[ ! " ${selected_regions[@]} " =~ " $region " ]]; then
                        selected_regions+=("$region")
                    else
                        echo -e "${YELLOW}Регион '$region' уже выбран.${NC}"
                    fi
                else
                    echo -e "${YELLOW}Похоже, что ты ошибся. Снова.${NC}"
                fi
            done

            for region in "${selected_regions[@]}"; do
                ipset_file="./regions/$region/${region}-voice-ipset"
                if [[ -f "$ipset_file" ]]; then
                    selected_ipset_files+=("$ipset_file")
                else
                    echo -e "${RED}IPset файл для региона '$region' не найден.${NC}"
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
        echo -e "${RED}Завершение скрипта.${NC}"
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
                echo "add $ipset_name $ip" >> "$tmp_ipset_restore_file"
                existing_ips_array["$ip"]=1
            fi
        done < "$ipset_file"
    done

    if [[ -s "$tmp_ipset_restore_file" ]]; then
        sudo ipset restore < "$tmp_ipset_restore_file"
        count=$(wc -l < "$tmp_ipset_restore_file")
        echo -e "${GREEN}Загружено $count IP адреса(ов) в список '$ipset_name'.${NC}"
    else
        echo -e "${YELLOW}Нет новых IP адресов для добавления в IPset.${NC}"
    fi

    rm -f "$tmp_ipset_restore_file"

    echo -e "${GREEN}Все IPset списки сгенерированы и готовы к использованию.${NC}"
fi
