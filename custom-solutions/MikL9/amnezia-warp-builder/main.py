import socket
import os
from datetime import datetime
from dotenv import load_dotenv

# Загружаем переменные из .env файла
load_dotenv()


# Функция для получения IP-адресов из хоста
def get_ip_from_host(host):
    try:
        return socket.gethostbyname(host)
    except socket.gaierror:
        return None


# Шаг 1. Получение IP-адресов из файла хостов
def get_ips_from_hosts(file_path):
    ip_addresses = []
    with open(file_path, 'r') as f:
        for line in f:
            host = line.strip()
            if host:
                ip = get_ip_from_host(host)
                if ip:
                    ip_addresses.append(ip)
    return ip_addresses


# Шаг 2. Получение IP-адресов из файлов ips-by-region
def get_ips_from_region(directory_path):
    ip_addresses = []
    for file_name in os.listdir(directory_path):
        file_path = os.path.join(directory_path, file_name)
        with open(file_path, 'r') as f:
            for line in f:
                ip = line.strip()
                if ip:
                    ip_addresses.append(ip)
    return ip_addresses


# Шаг 3. Формирование конфигурации и запись в файл
def generate_warp_conf(ip_addresses, output_file):
    # Загружаем данные из .env файла
    private_key = os.getenv("PrivateKey")
    address = os.getenv("Address")
    dns = os.getenv("DNS")
    public_key = os.getenv("PublicKey")
    endpoint = os.getenv("Endpoint")

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
    with open(output_file, 'w') as f:
        f.write(template)


# Основная логика
def main():
    # Пути к файлам
    hosts_file = '../discord-domains-list'
    region_directory = '../ips-by-region'

    # Шаг 1. Получаем IP-адреса с хостов
    host_ips = get_ips_from_hosts(hosts_file)

    # Шаг 2. Получаем IP-адреса из файлов в папке ips-by-region
    region_ips = get_ips_from_region(region_directory)

    # Объединяем все IP-адреса
    all_ips = host_ips + region_ips

    # Шаг 3. Генерация файла конфигурации
    current_date = datetime.now().strftime("%Y-%m-%d")
    output_file = f'warp{current_date}.conf'
    generate_warp_conf(all_ips, output_file)

    print(f"Конфигурационный файл '{output_file}' успешно создан.")


if __name__ == "__main__":
    main()
