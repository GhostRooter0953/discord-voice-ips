import socket
import json
import os
from datetime import datetime
from dotenv import load_dotenv
from utils import find_project_root
from utils import panic_message

# Загружаем переменные из .env файла
load_dotenv()


# Функция для получения IP-адресов из хоста
def get_ip_from_host(host):
    try:
        return socket.gethostbyname(host)
    except socket.gaierror:
        print(f"Host '{host}' not found.")
        return None


# Шаг 1. Получение IP-адресов из файла хостов
def get_ips_from_hosts(file_path, extended_json_file):
    ip_addresses = set()  # Используем множество для автоматического удаления дубликатов

    try:
        # Получение из file_path
        with open(file_path, 'r') as f:
            for line in f:
                host = line.strip()
                if host:
                    ip = get_ip_from_host(host)
                    if ip:
                        ip_addresses.add(ip)  # Добавляем IP в множество
    except FileNotFoundError as e:
        panic_message(f"File not found: {e}")

    # Дозаполнение из extended_json_file
    extended_host_ips = get_ips_from_json(extended_json_file)
    ip_addresses.update(extended_host_ips)  # Обновляем множество новыми IP

    return list(ip_addresses)  # Преобразуем множество обратно в список перед возвратом


# Шаг 3. Чтение JSON файла с IP адресами после генерации
def get_ips_from_json(json_file):
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        return [entry['ip'] for entry in data if entry['ip'] != ""]
    except FileNotFoundError as e:
        panic_message(f"File not found: {e}")


# Шаг 4. Формирование конфигурации и запись в файл
def generate_warp_conf(ip_addresses, output_file):
    # Загружаем данные из .env файла
    private_key = os.getenv("PrivateKey")
    address = os.getenv("Address")
    dns = os.getenv("DNS")
    public_key = os.getenv("PublicKey")
    endpoint = os.getenv("Endpoint")

    if not (private_key and address and dns and public_key and endpoint):
        panic_message("Заполните все поля .env!")

    # Формируем шаблон конфигурации с данными из .env
    template = f"""
[Interface]
PrivateKey = {private_key}
S1 = 0
S2 = 0
Jc = 120
Jmin = 23
Jmax = 911
H1 = 1
H2 = 2
H3 = 3
H4 = 4
Address = {address}
DNS = {dns}

[Peer]
PublicKey = {public_key}
AllowedIPs = {', '.join(ip_addresses)}
Endpoint = {endpoint}
"""
    try:
        with open(output_file, 'w') as f:
            f.write(template)
    except FileNotFoundError as e:
        panic_message(f"File not found: {e}")


# Основная логика
def main():
    # Пути к скриптам и файлам
    root_path = find_project_root(os.path.dirname(__file__), ".git")
    hosts_file = os.path.join(root_path, 'discord-domains-list')
    region_json_file = os.path.join(root_path, 'amnezia-voice-ip.json')
    domains_json_file = os.path.join(root_path, "amnezia-discord-domains.json")

    # Шаг 1. Получаем IP-адреса с хостов
    host_ips = get_ips_from_hosts(hosts_file, domains_json_file)

    # Шаг 4. Получаем IP-адреса из сгенерированного JSON файла
    region_ips = get_ips_from_json(region_json_file)

    # Объединяем все IP-адреса
    all_ips = host_ips + region_ips

    # Шаг 5. Генерация файла конфигурации
    current_date = datetime.now().strftime("%Y-%m-%d")
    output_file = f'warp{current_date}.conf'
    generate_warp_conf(all_ips, output_file)

    print(f"Конфигурационный файл '{output_file}' успешно создан.")


if __name__ == "__main__":
    main()
