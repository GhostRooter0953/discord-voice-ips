import sys
from pathlib import Path


def find_root_path():
    # Получаем путь к исполняемому файлу
    current_path = Path(sys.executable).resolve()

    # Ищем корневую директорию проекта
    for parent in current_path.parents:
        if parent.name == 'discord-voice-ips-master' or parent.name == 'discord-voice-ips-amneziaWG' or parent.name == 'discord-voice-ips':
            return parent
        if (parent / 'discord-domains-list').exists() or (parent / '.gitignore').exists():
            return parent

    return current_path


class ConfigurationError(Exception):
    pass


def panic_message(message):
    print(f"Ошибка выполнения программы: {message}")
    raise ConfigurationError(message)
