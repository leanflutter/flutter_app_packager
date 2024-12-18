---
title: AppImage
---

## Requirements

- `locate`

  On Ubuntu/Debian based linux, run:
  ```bash
  $ sudo apt install locate
  ```
- [appimagetool](https://github.com/AppImage/appimagetool)

To install appimagetool, run:

```bash
wget -O appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool
mv appimagetool /usr/local/bin/
```

> Last command may require `sudo` privileges

## Usage

Add `make_config.yaml` to your project `linux/packaging/appimage` directory.

```yaml
display_name: Hello World

icon: assets/logo.png

keywords:
  - Hello
  - World
  - Test
  - Application

generic_name: Cool Application

actions:
  - name: Say Hi
    label: say-hi
    arguments:
      - --say
      - hi
  - name: Say Bye
    label: say-bye
    arguments:
      - --say
      - bye

categories:
  - Music

startup_notify: true

# You can specify the shared libraries that you want to bundle with your app
#
# flutter_distributor automatically detects the shared libraries that your app
# depends on, but you can also specify them manually here.
# 
# The following example shows how to bundle the libcurl library with your app.
#
# include:
#   - libcurl.so.4
include: []

# You can also specify [metainfo](https://www.freedesktop.org/software/appstream/metainfocreator/#/) file
# which contains metadata of the app.
# metainfo: linux/packaging/myappid.appdata.xml
```

Run:

```bash
flutter_distributor package --platform linux --targets appimage
```

## Related Links

- [Build and release an Linux app](https://docs.flutter.dev/deployment/linux)
- [Introduction to AppImage package format](https://docs.appimage.org/)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)
- [AppStream Metainfo Specification](https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html)
