import json
import subprocess

# Чтение IP-адресов из файла
with open('voice_domains/discord-voice-ip-list', 'r') as file:
    ip_addresses = [line.strip() for line in file.readlines()]

# Создание структуры JSON
data = {
    "version": 1,
    "rules": [
        {
            "ip_cidr": ip_addresses
        }
    ]
}

# Запись JSON в файл
json_file_name = 'sing-box_source.json'
with open(json_file_name, 'w') as json_file:
    json.dump(data, json_file, indent=2)

# Компиляция JSON в бинарный rule-set
output_file_name = 'sing-box_compiled.srs'
subprocess.run(['sing-box', 'rule-set', 'compile', '--output', output_file_name, json_file_name])