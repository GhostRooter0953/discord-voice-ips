import sys
from pathlib import Path


def find_root_path():
    # Получаем путь к исполняемому файлу
    current_path = Path(sys.executable).resolve()

    # Ищем корневую директорию проекта
    for parent in current_path.parents:
        if (parent / 'setup.py').exists() or (parent / '.git').exists():
            return parent

    return current_path


class ConfigurationError(Exception):
    pass


def panic_message(message):
    print(f"Ошибка выполнения программы: {message}")
    raise ConfigurationError(message)
