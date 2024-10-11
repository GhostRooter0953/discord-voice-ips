#!/bin/bash

default_regions=("russia" "bucharest" "finland" "frankfurt" "madrid" "milan" "rotterdam" "stockholm" "warsaw")

if [ -n "$1" ]; then
    regions=("$1")
else
    regions=("${default_regions[@]}")
fi

total_domains=15000
temp_files=()

kill -sighup $(pgrep dnsmasq) 2> /dev/null || echo "Куда же подевался наш dnsmasq?"

check_domain() {
    domain=$1
    region=$2
    directory="./regions/$region"
    temp_file="$3"

    mkdir -p "$directory"

    ip=$(dig A +short "$domain" | grep -Evi  "(warning|timed out|no servers)")
    
    if [ -n "$ip" ]; then
        echo "$domain: $ip" >> "$directory"/"$region"-voice-resolved
        echo "$domain" >> "$directory"/"$region"-voice-domains
        echo "$ip" >> "$directory"/"$region"-voice-ip
        echo "add unblock $ip" >> "$directory"/"$region"-voice-ipset
    fi
    
    {
        flock -x 200
        count=$(<"$temp_file")
        count=$((count + 1))
        
        echo $count > "$temp_file"
        
        percent=$(( (count * 100) / total_domains ))
        
        printf "\rПрогресс: %d%%" "$percent"
    } 200>"$temp_file.lock"
}

export -f check_domain 
export total_domains

for region in "${regions[@]}"; do 
    echo ""
    echo "Генерируем и резолвим домены для региона: $region"

    directory="./regions/$region"

    if [ -d "$directory" ]; then 
        rm -rf "${directory:?}/"* 
    fi

    temp_file=$(mktemp)
    echo 0 > "$temp_file"
    temp_files+=("$temp_file")

    start_time=$(date +%s)
    start_date=$(date +'%d.%m.%Y в %H:%M:%S')

   seq 1 "$total_domains" | parallel -j 60 check_domain "${region}{}.discord.gg" "$region" "$temp_file"

   end_time=$(date +%s)
   execution_time=$((end_time - start_time))
   domains_resolved=$(wc -l < "$directory"/"$region"-voice-voice-resolved)

   echo ""
   echo "Успех!"
   echo "Время запуска: $start_date"
   echo "Время выполнения: $(date -ud "@$execution_time" +'%H:%M:%S')"
   echo "Доменов зарезолвили: $domains_resolved"
done

for temp_file in "${temp_files[@]}"; do
   rm -f "$temp_file"
done
