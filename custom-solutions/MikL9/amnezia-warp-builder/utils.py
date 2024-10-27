import sys
import os
from pathlib import Path


def find_root_path():
    # Определяем путь к файлу
    if hasattr(sys, 'gettrace') and sys.gettrace():
        # Если запущено в режиме отладки, используем текущий путь файла
        current_path = Path(__file__).resolve()
    else:
        # В других случаях (например, при запуске из venv) указываем путь вручную или относительно
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
