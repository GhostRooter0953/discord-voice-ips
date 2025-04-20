# 📌 Что это и зачем?  

**Репозиторий содержит списки доменов и IP основных/голосовых серверов Discord + инструменты для парсинга, резолвинга, работы с IPset и конвертации в JSON (_для Amnezia_). Всё это поможет настроить "корректную" маршрутизацию для его "стабильной" работы в непростые времена 😈**  

---

## 📂 Структура Репозитория  

### 🛠 Скрипты  

| Скрипт | Описание |
|--------|----------|
| `main-domains-resolver.sh` | Резолвит основные домены Discord, сохраняет их IP и генерирует JSON список готовый к импорту в Amnezia. |
| `voice-domains-generator.sh` | Генерирует и резолвит домены голосовых серверов для указанных регионов методом перебора `region[1-15000].discord.gg`. Записывает результат в фолдер `regions/` |
| `json-voice-ip-converter.sh` | Конвертирует результаты резолвинга голосовых серверов в JSON-формат готовый к импорту в Amnezia. |
| `ipset-adder.sh` | Создает IPset списки и добавляет в них IP-адреса, а также импортирует их в заданный IPset лист (_по умолчанию `unblock`_). |

### 📁 Каталоги  

📂 **amnezia/** – JSON-файлы с IP-адресами для Amnezia.  
📂 **regions/** – списки IP-адресов голосовых серверов по регионам.  
📂 **main_domains/** – списки основных доменов и IP.  
📂 **voice_domains/** – списки голосовых доменов и IP.  
📂 **custom-solutions/** – решения от **заинтересованных** и **неравнодушных**.  

---

## 🚀 Использование  

### 🔻 Резолвинг основных серверов Discord  
🔹 Запуск по умолчанию:  
```bash
./main-domains-resolver.sh
```
✅ Результаты сохраняются по пути `main_domains/discord-main-ip-list` и `amnezia/amnezia-discord-domains.json`  

---

### 🔻 Генерация и резолвинг доменов голосовых серверов  
🔹 Запуск по умолчанию:  
```bash
./voice-domains-generator.sh
```
🔹 Запуск для конкретного региона можно осуществить передав его 'имя' в качестве аргумента:  
```bash
./voice-domains-generator.sh singapore
```
✅ Результаты сохраняются в фолдер `regions/<имя региона>`  

---
> _Регионы генерируемые по умолчанию: `bucharest`, `finland`, `frankfurt`, `madrid`, `milan`, `rotterdam`, `stockholm`, `warsaw`_  
> _Отредактируйте переменную `DEFAULT_REGIONS` в `voice-domains-generator.sh` перед запуском, если есть необходимость изменить этот пул_  
---

### 🔻 Конвертация в JSON для Amnezia  
🔹 Запуск по умолчанию:  
```bash
./json-voice-ip-converter.sh
```
✅ Результаты сохраняются в фолдер `amnezia/`  

---

### 🔻 Работа с IPset
🔹 Добавить IP-адреса голосовых и основных доменов в IPset лист `unblock` (_такое имя листа по умолчанию_):  
```bash
./ipset-adder.sh auto
```
🔹 Добавить вышеперечисленное в кастомный IPset лист:  
```bash
./ipset-adder.sh list <ip_list_name>
```
🔹 Просто сгенерировать списки в IPset формате:  
```bash
./ipset-adder.sh noipset
```
🔹 Запуск в интерактивном режиме с выбором опций (_в том числе с возможностью добавить только ГС или ОС_):  
```bash
./ipset-adder.sh
```

---

## ⚙️ Требования

🔹 `jq` – для работы с JSON.  
🔹 `parallel` – для параллельной обработки резолвинга.  

---

## 🔥 Ветки `light` и `light-no-timeout`

Для роутеров с установленным **KVAS** доступна облегчённая версия репозитория в ветках:  
🔹 [`light`](https://github.com/GhostRooter0953/discord-voice-ips/tree/light) – добавляет нулевые таймауты в IPset. Ветка ориентирована на **актуальную** версию КВАС'а, в бете которого используются таймауты.  
🔹 [`light-no-timeout`](https://github.com/GhostRooter0953/discord-voice-ips/tree/light-no-timeout) – без таймаутов в IPset, что подходит для **релизной** версии КВАС'а (_как и ветка `master`_).  
📌 **Подробнее о чудо-скрипте:** [kvas-adder](https://github.com/GhostRooter0953/discord-ips-kvas-adder)  

---

## 📖 Короткий мануал по **Amnezia**

🔹 **Скачайте [репозиторий](https://github.com/GhostRooter0953/discord-voice-ips/tree/master)**  
🔹 **Включите раздельное туннелирование в Amnezia**  
🔹 **Выберите в селекторе "Только адреса из списка должны открываться через"**  
🔹 **Импортируйте списки:**  
📂 [Основные домены](https://github.com/GhostRooter0953/discord-voice-ips/blob/master/amnezia/amnezia-discord-domains.json)  
🎧 [Голосовые домены](https://github.com/GhostRooter0953/discord-voice-ips/blob/master/amnezia/amnezia-voice-ip.json) (_или конкретный регион_)  
🔹 **Подключитесь и проверьте работу Discord**  

---

## 🔧 To-Do  

🔹 **Доработка режимов под бета-версии КВАС'а (_ветка light_)**  
🔹 **Сканер и резолвер сабдоменов, т.к. периодчески возникают подобные [ситуации](https://github.com/GhostRooter0953/discord-voice-ips/issues/1#issuecomment-2408466714)**  
🔹 **Механизм автоматической актуализации IP списков и доменов в репозитории**  
