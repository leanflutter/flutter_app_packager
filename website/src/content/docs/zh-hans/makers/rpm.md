---
title: RPM
---

## 必要条件

- [patchelf](https://github.com/NixOS/patchelf)
- [rpmbuild](https://rpm-packaging-guide.github.io/#prerequisites)

安装要求：

- Debian/Ubuntu: `apt install rpm patchelf`
- Fedora: `dnf install gcc rpm-build rpm-devel rpmlint make python bash coreutils diffutils patch rpmdevtools patchelf`
- Arch: `yay -S rpmdevtools patchelf` or `pamac install rpmdevtools patchelf`

## 用法

将 `make_config.yaml` 添加到您的项目 `linux/packaging/rpm` 目录。

```yaml
package_name: hello-world
icon: assets/logo.png
summary: A really cool application
group: Application/Emulator
vendor: Kingkor Roy Tirtho
packager: Kingkor Roy Tirtho
packagerEmail: krtirtho@gmail.com
license: GPLv3
url: https://github.com/leanflutter/flutter_distributor

display_name: Hello World

keywords:
  - Hello
  - World
  - Test
  - Application

generic_name: Cool Application

categories:
  - Cool
  - Awesome

startup_notify: true
```

运行：

```
flutter_distributor package --platform linux --targets rpm
```

## 相关链接

- [构建和发布 Linux 应用程序](https://docs.flutter.dev/deployment/linux)
- [RPM 打包，它是如何工作的](https://rpm-packaging-guide.github.io/)
