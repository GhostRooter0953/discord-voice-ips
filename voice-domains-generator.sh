#!/bin/sh

default_regions="russia bucharest finland frankfurt madrid milan rotterdam stockholm warsaw"

regions="${1:-$default_regions}"

total_domains=15000

kill -sighup $(pgrep dnsmasq) 2> /dev/null || echo "Куда же подевался наш dnsmasq?"

check_domain() {
    domain=$1
    region=$2

    mkdir -p "$directory"

    ip=$(dig A +short "$domain" | grep -Evi "(warning|timed out|no servers|mismatch)")

    [ -n "$ip" ] && {
        echo "$domain: $ip" >> "$directory/$region-voice-resolved"
        echo "$domain" >> "$directory/$region-voice-domains"
        echo "$ip" >> "$directory/$region-voice-ip"
        echo "add unblock $ip" >> "$directory/$region-voice-ipset"
    }
}

for region in $regions; do
    echo "\nГенерируем и резолвим домены для региона: $region"
    directory="./regions/$region"

    [ -z "$directory" ] && {
        echo 'Чуть не сделали rm -rf /*'
        exit 1
    }
    rm -rf "${directory:?}"/*

    start_time=$(date +%s)
    start_date=$(date +'%d.%m.%Y в %H:%M:%S')

    resolved_count=0

   for i in $(seq 1 "$total_domains"); do
       check_domain "${region}${i}.discord.gg" "$region"
       resolved_count=$((resolved_count + 1))

       printf "\rПрогресс: $(( (resolved_count * 100) / total_domains ))%%"
   done

   end_time=$(date +%s)
   execution_time=$((end_time - start_time))
   domains_resolved=$(wc -l < "$directory"/"$region"-voice-resolved)

   echo ""
   echo "Успех!"
   echo "Время запуска: $start_date"
   echo "Время выполнения: $(date -ud "@$execution_time" +'%H:%M:%S')"
   echo "Доменов зарезолвили: $domains_resolved"
done
