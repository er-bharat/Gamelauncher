nuitka \
  --standalone \
  --onefile \
  --include-data-files=main.qml=main.qml \
  --nofollow-import-to=tkinter,test,unittest \
  --lto=yes \
  --remove-output \
  --assume-yes-for-downloads \
  --output-dir=build \
  --output-filename=GameLauncher \
  main.py
