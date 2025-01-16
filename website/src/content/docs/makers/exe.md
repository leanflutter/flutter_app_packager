---
title: exe
---

## Requirements

- [`Inno Setup 6`](https://jrsoftware.org/isinfo.php)

## Usage

Add `make_config.yaml` to your project `windows/packaging/exe` directory.

```yaml
# The value of AppId uniquely identifies this application.
# Do not use the same AppId value in installers for other applications.
app_id: 5B599538-42B1-4826-A479-AF079F21A65D
publisher: LeanFlutter
publisher_url: https://github.com/leanflutter/flutter_distributor
display_name: Hello 世界
create_desktop_icon: true
# See: https://jrsoftware.org/ishelp/index.php?topic=setup_defaultdirname
# install_dir_name: "D:\\HELLO-WORLD"
# This path is relative to the root directory of your project; The format of icon file must be ico, can not be png or others
# setup_icon_file: windows\runner\resources\app_icon.ico
locales:
  - en
  - zh
```

Run:

```
flutter_distributor package --platform windows --targets exe
```

## Advanced usage

### Custom Inno Setup template

By default, `flutter_distributor` will generate an Inno Setup configuration (`.iss`) based on an internal template on build time, and populate it with the values provided in `make_config.yaml`. If you need more control over the Inno Setup configuration, you can provide a custom template using the `script_template` option.

For example:

1. Add `script_template: inno_setup.iss` to your `make_config.yaml`
2. Create the `inno_setup.iss` in the same directory
3. Copy the [original template](https://github.com/leanflutter/flutter_distributor/blob/main/packages/flutter_app_packager/lib/src/makers/exe/inno_setup/inno_setup_script.dart) from the source code and adjust it.

## Related Links

[https://jrsoftware.org/isinfo.php](https://jrsoftware.org/isinfo.php)
