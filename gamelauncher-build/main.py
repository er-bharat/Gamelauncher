import sys
import os
import configparser
from PySide6.QtCore import QObject, Slot, QUrl, QProcess
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

# Paths
SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
DEFAULT_INI = os.path.join(SCRIPT_DIR, "games.ini")
HOME_INI = os.path.join(os.path.expanduser("~"), ".gamelauncher", "games.ini")

# Use home .gamelauncher/games.ini if default one doesn't exist
if not os.path.exists(DEFAULT_INI):
    # Ensure ~/.gamelauncher exists
    os.makedirs(os.path.dirname(HOME_INI), exist_ok=True)

    # Create a default games.ini if it doesn't exist
    if not os.path.exists(HOME_INI):
        with open(HOME_INI, 'w', encoding='utf-8') as f:
            f.write(
                "# Example Game Entry\n"
                "[ExampleGame]\n"
                "exec = echo 'Launching Example Game'\n"
                "image = example.png\n"
                "title = Example Game\n"
            )

INI_FILE = DEFAULT_INI if os.path.exists(DEFAULT_INI) else HOME_INI
QML_FILE = os.path.join(SCRIPT_DIR, "main.qml")

class Backend(QObject):
    """Backend exposed to QML with methods to launch and edit games."""

    @Slot(str)
    def launch(self, command: str):
        if not command.strip():
            return

        import platform
        if platform.system() == "Windows":
            QProcess.startDetached("cmd.exe", ["/C", command])
        else:
            QProcess.startDetached("bash", ["-c", command])

    @Slot()
    def edit_ini(self):
        import platform
        if platform.system() == "Windows":
            QProcess.startDetached("notepad.exe", [INI_FILE])
        else:
            QProcess.startDetached("kate", [INI_FILE])

def load_games(path: str):
    """Parse INI into a list of game dicts for QML."""
    cp = configparser.ConfigParser()
    cp.read(path, encoding="utf-8")
    games = []

    for section in cp.sections():
        cmd = cp.get(section, "exec", fallback="")
        image = cp.get(section, "image", fallback="")
        title = cp.get(section, "title", fallback=section)

        # Convert image path to file:// URL for QML
        if not os.path.isabs(image):
            image = os.path.abspath(os.path.join(os.path.dirname(path), image))
        image_url = QUrl.fromLocalFile(image).toString()

        games.append({"exec": cmd, "image": image_url, "title": title})
    return games

if __name__ == "__main__":
    app = QApplication(sys.argv)
    game_list = load_games(INI_FILE)
    backend = Backend()

    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()
    ctx.setContextProperty("gameList", game_list)
    ctx.setContextProperty("backend", backend)

    engine.load(QUrl.fromLocalFile(QML_FILE))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
