import tkinter as tk
import os
from dotenv import set_key
import sys
import io
from datetime import datetime
from utils import find_project_root
import wapr_generation as warp


# GUI для ввода данных
def create_gui():
    def save_and_run():
        # Сохранение данных в .env
        set_key('.env', 'PrivateKey', private_key_entry.get())
        set_key('.env', 'Address', address_entry.get())
        set_key('.env', 'DNS', dns_entry.get())
        set_key('.env', 'PublicKey', public_key_entry.get())
        set_key('.env', 'Endpoint', endpoint_entry.get())

        # Перенаправление вывода консоли в текстовый виджет
        old_stdout = sys.stdout
        sys.stdout = mystdout = io.StringIO()

        try:
            # Выполнение основной логики
            main()
        finally:
            # Восстановление стандартного вывода
            sys.stdout = old_stdout

        # Вывод результата в текстовый виджет
        console_output.delete(1.0, tk.END)
        console_output.insert(tk.END, mystdout.getvalue())

    root = tk.Tk()
    root.title("Настройки конфигурации")
    root.geometry("600x640")  # Увеличиваем размер окна

    tk.Label(root, text="PrivateKey").grid(row=0, column=0)
    private_key_entry = tk.Entry(root, width=50)  # Увеличиваем ширину поля
    private_key_entry.insert(0, os.getenv("PrivateKey", ""))
    private_key_entry.grid(row=0, column=1)

    tk.Label(root, text="Address").grid(row=1, column=0)
    address_entry = tk.Entry(root, width=50)  # Увеличиваем ширину поля
    address_entry.insert(0, os.getenv("Address", ""))
    address_entry.grid(row=1, column=1)

    tk.Label(root, text="DNS").grid(row=2, column=0)
    dns_entry = tk.Entry(root, width=50)  # Увеличиваем ширину поля
    dns_entry.insert(0, os.getenv("DNS", ""))
    dns_entry.grid(row=2, column=1)

    tk.Label(root, text="PublicKey").grid(row=3, column=0)
    public_key_entry = tk.Entry(root, width=50)  # Увеличиваем ширину поля
    public_key_entry.insert(0, os.getenv("PublicKey", ""))
    public_key_entry.grid(row=3, column=1)

    tk.Label(root, text="Endpoint").grid(row=4, column=0)
    endpoint_entry = tk.Entry(root, width=50)  # Увеличиваем ширину поля
    endpoint_entry.insert(0, os.getenv("Endpoint", ""))
    endpoint_entry.grid(row=4, column=1)

    tk.Button(root, text="Сохранить и Запустить", command=save_and_run).grid(row=5, columnspan=2)

    # Добавляем текстовый виджет для вывода консоли
    console_output = tk.Text(root, height=15, width=70)
    console_output.grid(row=6, columnspan=2)

    root.mainloop()


def main():
    # Пути к скриптам и файлам
    root_path = find_project_root(os.path.dirname(__file__), ".git")
    hosts_file = os.path.join(root_path, 'discord-domains-list')
    region_json_file = os.path.join(root_path, 'amnezia-voice-ip.json')
    domains_json_file = os.path.join(root_path, "amnezia-discord-domains.json")

    # Шаг 1. Получаем IP-адреса с хостов
    host_ips = warp.get_ips_from_hosts(hosts_file, domains_json_file)

    # Шаг 4. Получаем IP-адреса из сгенерированного JSON файла
    region_ips = warp.get_ips_from_json(region_json_file)

    # Объединяем все IP-адреса
    all_ips = host_ips + region_ips

    # Шаг 5. Генерация файла конфигурации
    current_date = datetime.now().strftime("%Y-%m-%d")
    output_file = f'warp{current_date}.conf'
    warp.generate_warp_conf(all_ips, output_file)

    print(f"Конфигурационный файл '{output_file}' успешно создан.")


if __name__ == "__main__":
    create_gui()
