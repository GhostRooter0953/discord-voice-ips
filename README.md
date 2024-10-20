# Что это и зачем?

Этот репозиторий содержит:
- Списки доменов и IP-адресов используемых голосовыми серверами Discord и в целом (_gui, api и т.д._)
- Скрипт для парсинга IP с готового списка сабдоменов голосовых каналов
- Скрипт создания IPset списка с последующей загрузкой в него получившихся IP списков
- Скрипт для генерации списка сабдоменов голосовых серверов в формате **region[1-15000].discord.gg** и их резолв с последующей записью в фолдер **regions**
- Скрипт для преобразования списков IP-адресов в JSON формат для удобного импорта в **Amnezia**

Репозиторий будет полезен тем, кто хочет настроить **"корректную"** маршрутизацию для обеспечения **"стабильной"** работы Discord.

## Структура Репозитория

- `main-domains-resolver.sh` - резолвит основные домены Discord в IP-адреса. Читает список доменов из main_domains/discord-main-domains-list, сохраняет IP-адреса в main_domains/discord-main-ip-list и генерирует JSON-файл amnezia/amnezia-discord-domains.json для использования с Amnezia VPN
- `voice-domains-generator.sh` - генерирует и резолвит домены голосовых серверов Discord для указанных регионов. Результаты сохраняются в соответствующих папках внутри regions/ и объединяются в общие списки в voice_domains/. (_шустрый, но зависит от CPU_) 
- `json-voice-ip-converter.sh` - конвертирует результаты резолвинга голосовых серверов из файлов в regions/ в JSON-формат для Amnezia VPN. Генерирует JSON-файлы для каждого региона в amnezia/ и общий файл amnezia/amnezia-voice-ip.json
- `ipset-adder.sh` - скрипт генерирует ipset списки из содержимого фолдеров `voice_domains` и `main_domains`, ипортирует их в заданный IPset при этом учитывая уже добавленные в него IP
- `amnezia` - фолдер со списками доменов и IP в формате JSON для настройки раздельного туннелирования в Amnezia
- `regions` - фолдер со списками IP голосовых каналов разбитых по регионам (_сгенерированный силами `voice-domains-generator`_)
- `main_domains` - фолдер со списками основных доменов и IP 
- `voice_domains` - фолдер со списками голосовых доменов и IP 
- `custom-solutions` - фолдер с решениями от **заинтересованных** и **неравнодушных**

### Папки

- **amnezia/**
Содержит JSON-файлы с IP-адресами для Amnezia VPN.
- **main_domains/**
  - `discord-main-domains-list` — список основных доменов Discord для резолвинга.
  - `discord-main-ip-list` — результат резолвинга основных доменов.
  - `discord-main-ipset-list` — IPSet список основных IP-адресов.
- **regions/**
Содержит папки по регионам с результатами резолвинга голосовых серверов.
  - **\<region\>/**
    - `<region>-voice-domains` — список зарезолвленных доменов.
    - `<region>-voice-ip` — список IP-адресов.
    - `<region>-voice-ipset` — IPSet список для региона.
    - `<region>-voice-resolved` — сопоставление доменов и IP.
- **voice_domains/**
  - `discord-voice-domains-list` — объединённый список доменов голосовых серверов.
  - `discord-voice-ip-list` — объединённый список IP-адресов.
  - `discord-voice-ipset-list` — объединённый IPSet список.

## Использование

### Резолвинг основных серверов Discord

1. Убедитесь, что main_domains/discord-main-domains-list заполнен.
2. Запустите скрипт:
```bash
./main-domains-resolver.sh
```
3. Результаты резолвинга будут сохранены в следующие файлы:
  - Основные IP-адреса: `./main_domains/discord-main-ip-list`
  - Основные IP-адреса в формате JSON: `./amnezia/amnezia-discord-domains.json`

### Генерация и резолвинг доменов голосовых серверов

1. Запуск без опций сегенерирует и зарезолвит регионы по умолчанию (_`$DEFAULT_REGIONS`_):
```bash
./voice-domains-generator.sh
```
Регионы генерируемые по умолчанию:
- russia
- bucharest
- finland
- frankfurt
- madrid
- milan
- rotterdam
- stockholm
- warsaw

_Отредактируйте переменную `DEFAULT_REGIONS` в `voice-domains-generator.sh`, если требуется_

2. Вы также можете указать в качестве аргумента конкретный регион, например тот, который отсутствует по умолчанию:
```bash
./voice-domains-generator.sh singapore
```
3. Результаты резолвинга для каждого региона сохраняются в соответствующие файлы в папке `regions/<имя региона>`.

### Конвертация в JSON для Amnezia VPN

Для конвертации списков основных и голосовых серверов в формат JSON выполните:

```bash
./json-voice-ip-converter.sh
```
Результаты будут сохранены в папку amnezia/.

### Работа с IPset

1. Для автоматического добавления IP-адресов основных и голосовых серверов в IPset (_по умолчанию список называется `unblock`, если у вас не так - не используйте аргумент `auto`_), используйте:
```bash
./ipset-adder.sh auto
```
2. Если вы не хотите использовать IPset, а только сгенерировать списки, выполните:
```bash
./ipset-adder.sh noipset
```
3. Запуск в интерактивном режиме:
```bash
./ipset-adder.sh
```

## Требования
- jq для работы с JSON
- parallel для параллельной обработки запросов резолвинга

## Ветка light

Для роутеров с установленным **KVAS** доступна облегчённая версия репозитория - ветка light. 
Подробнее в [этом](https://github.com/GhostRooter0953/discord-ips-kvas-adder) репо.

## Короткий мануал по работе с **Amnezia**

- Стянуть [репу](https://github.com/GhostRooter0953/discord-voice-ips/tree/master)
- Включить раздельное туннелирование в **Amnezia**, в селекторе выбрать **"Только адреса из списка должны открываться через VPN"**
- Импортировать список с [общими доменами](https://github.com/GhostRooter0953/discord-voice-ips/blob/master/amnezia/amnezia-discord-domains.json)
- Импортировать (_без замены_) список с [голосовыми каналами](https://github.com/GhostRooter0953/discord-voice-ips/blob/master/amnezia/amnezia-voice-ip.json) (_также можно взять и конкретный [регион](https://github.com/GhostRooter0953/discord-voice-ips/tree/master/amnezia)_)
- Подключиться к **Amnezia** и проверить работу Discord

## Схема структуры репозитория
```css
discord-voice-ips/
├── README.md
├── amnezia/
│   ├── amnezia-bucharest-voice-ip.json
│   ├── amnezia-discord-domains.json
│   ├── amnezia-dubai-voice-ip.json
│   ├── amnezia-finland-voice-ip.json
│   ├── amnezia-frankfurt-voice-ip.json
│   ├── amnezia-madrid-voice-ip.json
│   ├── amnezia-milan-voice-ip.json
│   ├── amnezia-rotterdam-voice-ip.json
│   ├── amnezia-russia-voice-ip.json
│   ├── amnezia-singapore-voice-ip.json
│   ├── amnezia-stockholm-voice-ip.json
│   ├── amnezia-voice-ip.json
│   └── amnezia-warsaw-voice-ip.json
├── custom-solutions/
├── ipset-adder.sh
├── json-voice-ip-converter.sh
├── main-domains-resolver.sh
├── voice-domains-generator.sh
├── main_domains/
│   ├── discord-main-domains-list
│   ├── discord-main-ip-list
│   └── discord-main-ipset-list
├── regions/
│   ├── bucharest/
│   │   ├── bucharest-voice-domains
│   │   ├── bucharest-voice-ip
│   │   ├── bucharest-voice-ipset
│   │   └── bucharest-voice-resolved
│   ├── dubai/
│   │   ├── dubai-voice-domains
│   │   ├── dubai-voice-ip
│   │   ├── dubai-voice-ipset
│   │   └── dubai-voice-resolved
│   ├── finland/
│   │   ├── finland-voice-domains
│   │   ├── finland-voice-ip
│   │   ├── finland-voice-ipset
│   │   └── finland-voice-resolved
│   ├── frankfurt/
│   │   ├── frankfurt-voice-domains
│   │   ├── frankfurt-voice-ip
│   │   ├── frankfurt-voice-ipset
│   │   └── frankfurt-voice-resolved
│   ├── madrid/
│   │   ├── madrid-voice-domains
│   │   ├── madrid-voice-ip
│   │   ├── madrid-voice-ipset
│   │   └── madrid-voice-resolved
│   ├── milan/
│   │   ├── milan-voice-domains
│   │   ├── milan-voice-ip
│   │   ├── milan-voice-ipset
│   │   └── milan-voice-resolved
│   ├── rotterdam/
│   │   ├── rotterdam-voice-domains
│   │   ├── rotterdam-voice-ip
│   │   ├── rotterdam-voice-ipset
│   │   └── rotterdam-voice-resolved
│   ├── russia/
│   │   ├── russia-voice-domains
│   │   ├── russia-voice-ip
│   │   ├── russia-voice-ipset
│   │   └── russia-voice-resolved
│   ├── singapore/
│   │   ├── singapore-voice-domains
│   │   ├── singapore-voice-ip
│   │   ├── singapore-voice-ipset
│   │   └── singapore-voice-resolved
│   ├── stockholm/
│   │   ├── stockholm-voice-domains
│   │   ├── stockholm-voice-ip
│   │   ├── stockholm-voice-ipset
│   │   └── stockholm-voice-resolved
│   └── warsaw/
│   │   ├── warsaw-voice-domains
│   │   ├── warsaw-voice-ip
│   │   ├── warsaw-voice-ipset
│   │   └── warsaw-voice-resolved
└── voice_domains/
    ├── discord-voice-domains-list
    ├── discord-voice-ip-list
    └── discord-voice-ipset-list
```

## To Do

- Сканер и резолвер сабдоменов, т.к. периодчески возникают подобные [ситуации](https://github.com/GhostRooter0953/discord-voice-ips/issues/1#issuecomment-2408466714)
- Механизм автоматической актуализации списков в репозитории
- `ipset-adder.sh`: парсинг существующих списков на основе регулярки ниже и предложение выбрать список, в который будет осуществляться импорт:
    ```bash
    ipset list -n | grep -vE '(NDM|UPNP)'
    ```
- `ipset-adder.sh`: добавить сценарий аналогичный `auto` для передачи имени списка в качестве аргумента
- `kvas-ipset-adder.sh`: добавление возможности передать аргумент, который будет подставляться в крон задании в качестве аргумента для `ipset-adder.sh`:
    ```bash
    SCRIPT_TO_RUN="ipset-adder.sh auto $1"
    ...
    "0 0 * * * cd $EXTRACTED_DIR && /opt/bin/bash $SCRIPT_TO_RUN"
    ```
---
