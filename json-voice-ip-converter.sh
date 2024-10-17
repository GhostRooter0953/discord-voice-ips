#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

output_file="./amnezia/amnezia-voice-ip.json"
tmp_output_file=$(mktemp)
echo "[" > "$tmp_output_file"
global_first=true

echo -e "\n${YELLOW}Подготавливаем данные для конвертации...${NC}"
total_lines=0
for region_dir in regions/*; do
    region_name=$(basename "$region_dir")
    input_file="${region_dir}/${region_name}-voice-resolved"
    if [[ -f "$input_file" ]]; then
        lines_in_file=$(wc -l < "$input_file")
        total_lines=$((total_lines + lines_in_file))
    fi
done

processed_lines=0

echo -e "\n${CYAN}Начинаем конвертацию в JSON...${NC}\n"

for region_dir in regions/*; do
    region_name=$(basename "$region_dir")
    input_file="${region_dir}/${region_name}-voice-resolved"

    if [[ -f "$input_file" ]]; then
        echo -e "${BLUE}Обрабатываем регион: ${MAGENTA}$region_name${NC}"

        regional_output_file="./amnezia/amnezia-${region_name}-voice-ip.json"
        tmp_regional_output_file=$(mktemp)
        echo "[" > "$tmp_regional_output_file"
        regional_first=true

        while IFS=':' read -r hostname ip; do
            hostname=$(echo "$hostname" | xargs)
            ip=$(echo "$ip" | xargs)

            if [[ -z "$hostname" || -z "$ip" ]]; then
                continue
            fi

            json_entry=$(jq -c -n --arg hostname "$hostname" --arg ip "$ip" \
                '{hostname: $hostname, ip: $ip}')

            if $global_first; then
                global_first=false
            else
                echo "," >> "$tmp_output_file"
            fi
            echo "  $json_entry" >> "$tmp_output_file"

            if $regional_first; then
                regional_first=false
            else
                echo "," >> "$tmp_regional_output_file"
            fi
            echo "  $json_entry" >> "$tmp_regional_output_file"

            processed_lines=$((processed_lines + 1))
            percent=$((processed_lines * 100 / total_lines))
            echo -ne "${NC}Общий прогресс: ${percent}% (${processed_lines}/${total_lines})${NC}\r"

        done < "$input_file"

        echo "]" >> "$tmp_regional_output_file"
        mv "$tmp_regional_output_file" "$regional_output_file"
        echo -e "\n${GREEN}Регион ${MAGENTA}$region_name ${GREEN}успешно обработан!${NC}\n"

    else
        echo -e "${RED}Не найден файл: $input_file${NC}"
    fi
done

echo "]" >> "$tmp_output_file"
mv "$tmp_output_file" "$output_file"

echo -e "${YELLOW}Конвертация завершена!${NC}\n"
echo -e "${GREEN}Содержимое всех списков записано в файл: ${MAGENTA}$output_file${NC}\n"
