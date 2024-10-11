#!/bin/bash

output_file="amnezia-voice-ip.json"
> "$output_file"

echo "[" >> "$output_file"

first_entry=true

for region_dir in regions/*; do
    region_name=$(basename "$region_dir")
    input_file="${region_dir}/${region_name}-voice-resolved"

    if [[ -f "$input_file" ]]; then
        echo "Конвертируем в JSON: $region_name"

        regional_output_file="./regions/$region_name/amnezia-${region_name}-voice-ip.json"
        > "$regional_output_file"
        echo "[" >> "$regional_output_file"

        regional_first_entry=true

        while IFS= read -r line; do
            hostname=$(echo "$line" | cut -d ':' -f 1 | xargs)
            ip=$(echo "$line" | cut -d ':' -f 2 | xargs)

            json_entry="{\"hostname\": \"$hostname\", \"ip\": \"$ip\"}"

            if [ "$first_entry" = true ]; then
                first_entry=false
            else
                echo "," >> "$output_file"
            fi

            echo "    $json_entry" >> "$output_file"

            if [ "$regional_first_entry" = true ]; then
                regional_first_entry=false
            else
                echo "," >> "$regional_output_file"
            fi

            echo "    $json_entry" >> "$regional_output_file"

        done < "$input_file"

        echo "]" >> "$regional_output_file"

    else
        echo "Куда пропал: $input_file?"
    fi
done

echo "]" >> "$output_file"

echo "Содержимое всех списков записано в $output_file."
