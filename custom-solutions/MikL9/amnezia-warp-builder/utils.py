import os


def find_project_root(current_path, marker='.git'):
    current_path = os.path.abspath(current_path)
    while current_path != os.path.dirname(current_path):
        if marker in os.listdir(current_path):
            return current_path
        current_path = os.path.dirname(current_path)
    return None


class ConfigurationError(Exception):
    pass


def panic_message(message):
    print(f"Ошибка выполнения программы: {message}")
    raise ConfigurationError(message)
