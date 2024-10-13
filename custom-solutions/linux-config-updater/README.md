# Discord Config Updater for Linux users

## Как использовать

### Требования к конфигурационному файлу Amnezia/WireGuard
Добавить следующие строчки в раздел ```[Peer]``` конфигурационного файла:
```shell
# Discord
AllowedIPs = <something>
# Discord Voice
AllowedIPs = <something>
```

Пример ```/etc/wireguard/client.conf```:
```
[Interface]
...

[Peer]
PublicKey = ...
Endpoint = ...
AllowedIPs = 10.0.13.0/24
# Discord
AllowedIPs = 10.0.13.0/24
# Discord Voice
AllowedIPs = 10.0.13.0/24
```

### Запустить
```shell
CONFIG_PATH="/etc/wireguard/client.conf" ./update_amnezia-discord.sh
```
Готово, конфиг обновлен. Можно перезапускать сервис.
