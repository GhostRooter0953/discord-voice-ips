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

    ip=$(dig A +short "$domain" | grep -Evi  "(warning|timed out|no servers|mismatch)")

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

all_ip_list="./discord-voice-ip-list"
all_ipset_list="./discord-voice-ipset-list"
all_domains_list="./discord-voice-domains-list"

> "$all_ip_list"
> "$all_ipset_list"
> "$all_domains_list"

for region in "${regions[@]}"; do
    echo -e "\nГенерируем и резолвим домены для региона: $region"
    directory="./regions/$region"

    [ -z "$directory" ] && {
        echo 'Чуть не сделали rm -rf /*'
        exit 1
    }
    rm -rf "${directory:?}"/*

    temp_file=$(mktemp)
    echo 0 > "$temp_file"
    temp_files+=("$temp_file")

    start_time=$(date +%s)
    start_date=$(date +'%d.%m.%Y в %H:%M:%S')

   seq 1 "$total_domains" | parallel -j 60 check_domain "${region}{}.discord.gg" "$region" "$temp_file"

   sort "$directory/$region-voice-ip" 2> /dev/null >> "$all_ip_list"
   sort "$directory/$region-voice-ipset" 2> /dev/null >> "$all_ipset_list"
   sort "$directory/$region-voice-domains" 2> /dev/null >> "$all_domains_list"

   end_time=$(date +%s)
   execution_time=$((end_time - start_time))
   domains_resolved=$(wc -l < "$directory"/"$region"-voice-resolved)

   echo ""
   echo "Успех!"
   echo "Время запуска: $start_date"
   echo "Время выполнения: $(date -ud "@$execution_time" +'%H:%M:%S')"
   echo "Доменов зарезолвили: $domains_resolved"
done

for temp_file in "${temp_files[@]}"; do
   rm -f "$temp_file"
done

   ip_count=$(wc -l < "$all_ip_list")
   echo -e "\nСписок "$all_ip_list" обновлён, зарезолвили $ip_count адреса(ов)\n"
