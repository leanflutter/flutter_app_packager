---
title: RPM
---

## Requires

- [patchelf](https://github.com/NixOS/patchelf)
- [rpmbuild](https://rpm-packaging-guide.github.io/#prerequisites)

Install requirements:

- Debian/Ubuntu: `apt install rpm patchelf`
- Fedora: `dnf install gcc rpm-build rpm-devel rpmlint make python bash coreutils diffutils patch rpmdevtools patchelf`
- Arch: `yay -S rpmdevtools patchelf` or `pamac install rpmdevtools patchelf`

## Usage

Add `make_config.yaml` to your project `linux/packaging/rpm` directory.

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

# You can also specify [metainfo](https://freedesktop.org/software/appstream/docs/chap-Quickstart.html) file
# which contains metadata of the app.
# metainfo: linux/packaging/myappid.appdata.xml
```

Run:

```
flutter_distributor package --platform linux --targets rpm
```

## Related Links

- [Build and release an Linux app](https://docs.flutter.dev/deployment/linux)
- [RPM packaging, how it works](https://rpm-packaging-guide.github.io/)
