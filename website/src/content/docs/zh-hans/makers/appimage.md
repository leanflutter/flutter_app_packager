---
title: AppImage
---

## 必要条件

- `locate`

  On Ubuntu/Debian based linux, run:
  ```bash
  $ sudo apt install locate
  ```
- [AppImageTool](https://github.com/AppImage/AppImageKit)

要安装 Appimage Builder，请运行：

```bash
wget -O appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool
mv appimagetool /usr/local/bin/
```

> 最后一条命令可能需要 `sudo` 权限

## 用法

将 `make_config.yaml` 添加到您的项目 `linux/packaging/appimage` 目录。

```yaml
package_name: hello_world
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

# 您可以指定要与您的应用捆绑的共享库
#
# flutter_distributor 会自动检测您的应用所依赖的共享库，但您也可以在此处手动指定它们。
# 
# 以下示例展示了如何将 libcurl 库与您的应用捆绑在一起
#
# include:
#   - libcurl.so.4
include: []
```

运行:

```bash
flutter_distributor package --platform linux --targets appimage
```

## 相关链接

- [构建和发布 Linux 应用程序](https://docs.flutter.dev/deployment/linux)
- [AppImage 包格式介绍](https://docs.appimage.org/)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)