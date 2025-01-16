---
title: exe
---

## 必要条件

- [`Inno Setup 6`](https://jrsoftware.org/isinfo.php)``

## 用法

将 `make_config.yaml` 添加到你的项目 `windows/packaging/exe` 目录。

```yaml
# AppId 的值唯一标识此应用。
# 不要在其他应用的安装程序中使用相同的 AppId 值。
app_id: 5B599538-42B1-4826-A479-AF079F21A65D
publisher: LeanFlutter
publisher_url: https://github.com/leanflutter/flutter_distributor
display_name: Hello 世界
create_desktop_icon: true
# See: https://jrsoftware.org/ishelp/index.php?topic=setup_defaultdirname
# install_dir_name: "D:\\HELLO-WORLD"
# 这里的路径是相对于项目根目录的路径； 图标格式必须是ico格式，不能是png或其它
# setup_icon_file: windows\runner\resources\app_icon.ico
locales:
  - en
  - zh
```

运行：

```
flutter_distributor package --platform windows --targets exe
```

## 高级用法

### 自定义 Inno Setup 模板

默认情况下，`flutter_distributor` 会在构建时基于内部模板生成一个 Inno Setup 配置（`.iss`），并将其填充到 `make_config.yaml` 中提供的值。如果你需要对 Inno Setup 配置进行更多控制，你可以使用 `script_template` 选项提供一个自定义模板。

例如：

1. 添加 `script_template: inno_setup.iss` 到你的 `make_config.yaml`
2. 在同一目录中创建 `inno_setup.iss` 
3. 从源代码中复制 [原始模板](https://github.com/leanflutter/flutter_distributor/blob/main/packages/flutter_app_packager/lib/src/makers/exe/inno_setup/inno_setup_script.dart) 并进行调整。

## 相关链接

[https://jrsoftware.org/isinfo.php](https://jrsoftware.org/isinfo.php)
