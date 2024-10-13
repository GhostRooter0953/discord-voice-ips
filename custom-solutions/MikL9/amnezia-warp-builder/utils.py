import os


def find_project_root(current_path, marker='.git'):
    current_path = os.path.abspath(current_path)
    while current_path != os.path.dirname(current_path):
        if marker in os.listdir(current_path):
            return current_path
        current_path = os.path.dirname(current_path)
    return None

def panic_message(message):
    print(f"PANIC: {message}")
    exit(1)  # Завершаем выполнение программы с кодом ошибки 1