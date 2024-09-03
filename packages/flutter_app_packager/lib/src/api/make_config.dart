import 'dart:ffi';
import 'dart:io';

import 'package:flutter_app_packager/src/api/make_error.dart';
import 'package:mustache_template/mustache.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

const _kArtifactName =
    '{{name}}{{#flavor}}-{{flavor}}{{/flavor}}-{{build_name}}+{{build_number}}{{#is_profile}}-{{build_mode}}{{/is_profile}}-{{platform}}{{#is_installer}}-setup{{/is_installer}}{{#ext}}.{{ext}}{{/ext}}';
const _kArtifactNameWithChannel =
    '{{name}}-{{channel}}-{{build_name}}+{{build_number}}{{#is_profile}}-{{build_mode}}{{/is_profile}}-{{platform}}{{#is_installer}}-setup{{/is_installer}}{{#ext}}.{{ext}}{{/ext}}';

class MakeConfig {
  late bool isInstaller = false;
  late String buildMode;
  late Directory buildOutputDirectory;
  late List<File> buildOutputFiles;
  late String platform;
  String? flavor;
  String? channel;

  /// https://mustache.github.io/mustache.5.html
  String? artifactName;
  late String packageFormat;
  late Directory outputDirectory;

  String get appName => pubspec.name;
  String get appBinaryName => pubspec.name;
  Version get appVersion => pubspec.version!;
  String get appBuildName => appVersion.toString().split('+').first;
  String get appBuildNumber => appVersion.toString().split('+').last;
  String? get arch => Abi.current().architecture?.name;

  Pubspec? _pubspec;
  Directory? _packagingDirectory;

  MakeConfig copyWith(MakeConfig makeConfig) {
    buildMode = makeConfig.buildMode;
    buildOutputDirectory = makeConfig.buildOutputDirectory;
    buildOutputFiles = makeConfig.buildOutputFiles;
    platform = makeConfig.platform;
    flavor = makeConfig.flavor;
    channel = makeConfig.channel;
    artifactName = makeConfig.artifactName;
    packageFormat = makeConfig.packageFormat;
    outputDirectory = makeConfig.outputDirectory;
    return this;
  }

  File get outputFile {
    if (packageFormat.isEmpty) {
      throw MakeError('Direct output is not a file');
    }
    return File(outputArtifactPath);
  }

  String get outputArtifactPath {
    String useArtifactName = _kArtifactName;
    if (channel != null) useArtifactName = _kArtifactNameWithChannel;
    if (artifactName != null) useArtifactName = artifactName!;

    Map<String, dynamic> variables = {
      'is_installer': isInstaller,
      'is_profile': buildMode == 'profile',
      'name': appName,
      'version': appVersion.toString(),
      'build_name': appBuildName,
      'build_number': appBuildNumber,
      'build_mode': buildMode,
      'platform': platform,
      'flavor': flavor,
      'channel': channel,
      'arch': arch,
      'ext': packageFormat.isEmpty ? null : packageFormat,
    };

    String filename = Template(useArtifactName).renderString(variables);

    Directory versionOutputDirectory =
        Directory('${outputDirectory.path}$appVersion');

    if (!versionOutputDirectory.existsSync()) {
      versionOutputDirectory.createSync(recursive: true);
    }

    return '${versionOutputDirectory.path}/$filename';
  }

  List<FileSystemEntity> get outputArtifacts {
    List<FileSystemEntity> artifacts = [];
    if (packageFormat.isEmpty) {
      artifacts.add(Directory(outputArtifactPath));
    } else {
      artifacts.add(File(outputArtifactPath));
    }
    return artifacts;
  }

  Directory get packagingDirectory {
    if (_packagingDirectory == null) {
      _packagingDirectory = Directory(
        outputArtifactPath.replaceAll('.$packageFormat', '_$packageFormat'),
      );
      if (_packagingDirectory!.existsSync()) {
        _packagingDirectory!.deleteSync(recursive: true);
      }
      _packagingDirectory!.createSync(recursive: true);
    }
    return _packagingDirectory!;
  }

  Pubspec get pubspec {
    if (_pubspec == null) {
      final yamlString = File('pubspec.yaml').readAsStringSync();
      _pubspec = Pubspec.parse(yamlString);
    }
    return _pubspec!;
  }

  Map<String, dynamic> toJson() {
    return {
      'isInstaller': isInstaller,
      'buildMode': buildMode,
      'buildOutputDirectory': buildOutputDirectory.path,
      'buildOutputFiles': buildOutputFiles.map((e) => e.path).toList(),
      'platform': platform,
      'flavor': flavor,
      'channel': channel,
      'artifactName': artifactName,
      'packageFormat': packageFormat,
      'outputDirectory': outputDirectory.path,
      'appName': appName,
      'appVersion': appVersion.toString(),
      'appBuildName': appBuildName,
      'appBuildNumber': appBuildNumber,
    }..removeWhere((key, value) => value == null);
  }
}

abstract class MakeConfigLoader {
  late String platform;
  late String packageFormat;

  MakeConfig load(
    Map<String, dynamic>? arguments,
    Directory outputDirectory, {
    required Directory buildOutputDirectory,
    required List<File> buildOutputFiles,
  });
}

class DefaultMakeConfigLoader extends MakeConfigLoader {
  @override
  MakeConfig load(
    Map<String, dynamic>? arguments,
    Directory outputDirectory, {
    required Directory buildOutputDirectory,
    required List<File> buildOutputFiles,
  }) {
    return MakeConfig()
      ..platform = platform
      ..buildMode = arguments?['build_mode']
      ..buildOutputDirectory = buildOutputDirectory
      ..buildOutputFiles = buildOutputFiles
      ..flavor = arguments?['flavor']
      ..channel = arguments?['channel']
      ..artifactName = arguments?['artifact_name']
      ..packageFormat = packageFormat
      ..outputDirectory = outputDirectory;
  }
}

class MakeLinuxPackageConfig extends MakeConfig {
  String? _appBinaryName;
  @override
  String get appBinaryName {
    if (_appBinaryName == null) {
      final cMakeListsFile = File('linux/CMakeLists.txt');
      final RegExp regex = RegExp(r'(?<=set\(BINARY_NAME\s")[^"]+(?="\))');
      final Match? match = regex.firstMatch(cMakeListsFile.readAsStringSync());

      if (match != null) {
        final String? binaryName = match.group(0);
        _appBinaryName = binaryName;
      } else {
        _appBinaryName = appName;
      }
    }
    return _appBinaryName!;
  }
}

extension _AbiArch on Abi {
  _Architecture? get architecture {
    switch (this) {
      case Abi.androidArm:
        return _Architecture.arm;
      case Abi.androidArm64:
        return _Architecture.arm64;
      case Abi.androidIA32:
        return _Architecture.ia32;
      case Abi.androidX64:
        return _Architecture.x64;
      case Abi.androidRiscv64:
        return _Architecture.riscv64;
      case Abi.fuchsiaArm64:
        return _Architecture.arm64;
      case Abi.fuchsiaX64:
        return _Architecture.x64;
      case Abi.fuchsiaRiscv64:
        return _Architecture.riscv64;
      case Abi.iosArm:
        return _Architecture.arm;
      case Abi.iosArm64:
        return _Architecture.arm64;
      case Abi.iosX64:
        return _Architecture.x64;
      case Abi.linuxArm:
        return _Architecture.arm;
      case Abi.linuxArm64:
        return _Architecture.arm64;
      case Abi.linuxIA32:
        return _Architecture.ia32;
      case Abi.linuxX64:
        return _Architecture.x64;
      case Abi.linuxRiscv32:
        return _Architecture.riscv32;
      case Abi.linuxRiscv64:
        return _Architecture.riscv64;
      case Abi.macosArm64:
        return _Architecture.arm64;
      case Abi.macosX64:
        return _Architecture.x64;
      case Abi.windowsArm64:
        return _Architecture.arm64;
      case Abi.windowsIA32:
        return _Architecture.ia32;
      case Abi.windowsX64:
        return _Architecture.x64;
      default:
        return null;
    }
  }
}

enum _Architecture {
  arm,
  arm64,
  ia32,
  x64,
  riscv32,
  riscv64,
}
