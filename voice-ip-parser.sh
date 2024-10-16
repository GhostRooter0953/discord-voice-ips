#!/bin/sh

# Функция Да/Нет
confirm() {
    while true; do
        read -p "$1 (Y/N): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Пожалуйста, ответьте Y или N";;
        esac
    done
}

# Очистка файлов перед началом работы скрипта
echo 'Очистка IP листов'
echo '' > discord-voice-ip-list
echo '' > discord-voice-ipset-list

# Сброс кэша DNS
kill -sighup $(pgrep dnsmasq) 2> /dev/null || echo "Куда же подевался наш dnsmasq?"

# Подсчитываем общее количество доменов из файла discord-voice-domains-list
total_domains=$(wc -l < discord-voice-domains-list)
        echo "Начинаем парсить IP голосовых серверов Discord"

count=0  # Инициализируем счётчик обработанных доменов

while IFS= read -r domain_name; do
    # Резолвим IP адреса и выкидываем лишнее
    ip=$(dig A +short "$domain_name" | grep -Evi  "(warning|timed out|no servers)")

    # Проверяем, что спарсили IP, а не пустоту
    if [ -n "$ip" ]; then
        # Записываем IP адреса в список
        echo "$ip" >> discord-voice-ip-list

        # Также генерируем IPset список
        echo "add kvas $ip" >> discord-voice-ipset-list
    fi

    count=$((count + 1)) # Подкручиваем счётчик

    # Вычисляем процент завершения и обновляем вывод
    percent=$(( (count * 100) / total_domains ))

    # Обновляем строку с прогрессом:
    printf "\rПарсим... Прогресс: %d%%" "$percent"

done < discord-voice-domains-list

echo -e "\nПарсинг завершён"

# Проверка наличия ipset списка unblock
if [ "$1" != "noipset" ]; then
    if ! ipset list | grep -q "^Name: kvas$"; then
        # Список 'unblock' не найден, запрашиваем у пользователя подтверждение на создание
        if [ "$1" != "auto" ]; then
            echo "Список 'unblock' не найден!"
            if confirm "Создаём список 'unblock'?"; then
                ipset create kvas hash:ip
                echo "Список создан"
            else
                echo "Пропускаем создание списка 'unblock'"
                exit 0  # Прерываем выполнение, если пользователь отказался от создания списка
            fi
        else
            # Автоматический режим: создаем список без подтверждения
            ipset create kvas hash:ip
            echo "Список 'unblock' создан"
        fi
    fi

    # Запрос на очистку списка unblock только если он существует
    if [ "$1" != "auto" ]; then
        if confirm "Чистим список 'unblock'?"; then
            ipset flush kvas
            echo "Список 'unblock' очищен"
        else
            echo "Пропускаем очистку 'unblock'"
        fi
    else
        # Автоматический режим: очищаем список без подтверждения
        ipset flush kvas
        echo "Список 'unblock' очищен"
    fi

    # Загрузка содержимого discord-voice-ipset-list в IPset список unblock
    if [ "$1" != "auto" ]; then
       if confirm "Загружаем адреса в IPset?"; then
           ipset restore < discord-voice-ipset-list
           count=$(wc -l < discord-voice-ipset-list)
           echo "Загружено $count IP адреса(ов) в список 'unblock'"
       fi
    else
       # Автоматический режим: загружаем без подтверждения
       ipset restore < discord-voice-ipset-list
       count=$(wc -l < discord-voice-ipset-list)
       echo "Загружено $count IP адреса(ов) в список 'unblock'"
    fi

else
    echo "Пропускаем танцы с IPset... Список с IP можно найти в 'discord-voice-ip-list'"
fi
