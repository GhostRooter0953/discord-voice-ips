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

OUTPUT_FILE="./amnezia/amnezia-voice-ip.json"
TMP_OUTPUT_FILE=$(mktemp)
echo "[" > "$TMP_OUTPUT_FILE"
global_first=true

log_info "Подготавливаем данные для конвертации..."
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

log_info "Начинаем конвертацию в JSON..."

process_region() {
    local region_dir="$1"
    local region_name
    region_name=$(basename "$region_dir")
    local input_file="${region_dir}/${region_name}-voice-resolved"
    if [[ ! -f "$input_file" ]]; then
        log_warn "${RED}${input_file}${NC} не найден – пропускаем регион ${MAGENTA}$region_name${NC}"
        line_skip
        return
    fi
    log_info "Конвертируем регион: ${MAGENTA}$region_name${NC}"
    local regional_output_file="./amnezia/amnezia-${region_name}-voice-ip.json"
    local tmp_regional_output_file
    tmp_regional_output_file=$(mktemp)
    echo "[" > "$tmp_regional_output_file"
    local regional_first=true

    while IFS=':' read -r hostname ip; do
        hostname=$(echo "$hostname" | xargs)
        ip=$(echo "$ip" | xargs)
        [[ -z "$hostname" || -z "$ip" ]] && continue

        json_entry=$(jq -c -n --arg hostname "$hostname" --arg ip "$ip" \
            '{hostname: $hostname, ip: $ip}')

        if $global_first; then
            global_first=false
        else
            echo "," >> "$TMP_OUTPUT_FILE"
        fi
        echo "  $json_entry" >> "$TMP_OUTPUT_FILE"

        if $regional_first; then
            regional_first=false
        else
            echo "," >> "$tmp_regional_output_file"
        fi
        echo "  $json_entry" >> "$tmp_regional_output_file"

        processed_lines=$((processed_lines + 1))
        percent=$(( processed_lines * 100 / total_lines ))
        echo -ne "${NC}Общий прогресс: ${percent}% (${processed_lines}/${total_lines})${NC}\r"
#        printf "\rОбщий прогресс: %d%% (%d/%d)" "$percent" "$processed_lines" "$total_lines"
    done < "$input_file"

    echo "]" >> "$tmp_regional_output_file"
    mv "$tmp_regional_output_file" "$regional_output_file"
    log_success "Регион ${MAGENTA}$region_name${NC} успешно обработан!"
    line_skip
}

for region_dir in regions/*; do
    if [[ -d "$region_dir" ]]; then
        process_region "$region_dir"
    fi
done

echo "]" >> "$TMP_OUTPUT_FILE"
mv "$TMP_OUTPUT_FILE" "$OUTPUT_FILE"

log_success "Конвертация завершена! Общий JSON файл записан: ${MAGENTA}$OUTPUT_FILE${NC}"
