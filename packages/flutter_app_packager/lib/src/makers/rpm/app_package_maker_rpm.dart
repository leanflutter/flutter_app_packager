import 'dart:io';

import 'package:flutter_app_packager/src/api/app_package_maker.dart';
import 'package:flutter_app_packager/src/makers/rpm/make_rpm_config.dart';
import 'package:flutter_app_packager/src/makers/rpm/rpmbuild.dart';
import 'package:path/path.dart' as path;
import 'package:shell_executor/shell_executor.dart';

class AppPackageMakerRPM extends AppPackageMaker {
  @override
  List<Command> get requirements => [rpmbuild];

  @override
  String get name => 'rpm';
  @override
  String get platform => 'linux';
  @override
  String get packageFormat => 'rpm';

  @override
  bool get isSupportedOnCurrentPlatform => Platform.isLinux;

  @override
  MakeConfigLoader get configLoader {
    return MakeRpmConfigLoader()
      ..platform = platform
      ..packageFormat = packageFormat;
  }

  @override
  Future<MakeResult> make(MakeConfig config) {
    return _make(
      config.buildOutputDirectory,
      outputDirectory: config.outputDirectory,
      makeConfig: config as MakeRPMConfig,
    );
  }

  Future<MakeResult> _make(
    Directory appDirectory, {
    required Directory outputDirectory,
    required MakeRPMConfig makeConfig,
  }) async {
    final files = makeConfig.toFilesString();

    Directory packagingDirectory = makeConfig.packagingDirectory;

    // making rpm setup directory

    final rpmbuild = [
      'BUILD',
      'BUILDROOT',
      'RPMS',
      'SOURCES',
      'SPECS',
      'SRPMS',
    ];

    final rpmbuildDirPath =
        path.join(packagingDirectory.absolute.path, 'rpmbuild');

    for (final dir in rpmbuild) {
      final dirPath = path.join(rpmbuildDirPath, dir);
      final dirFile = Directory(dirPath);
      if (!dirFile.existsSync()) {
        dirFile.createSync(recursive: true);
      }
    }

    // making rpmbuild/BUILD/[appName] directory
    final buildPath = path.join(rpmbuildDirPath, 'BUILD');
    final buildRoot = path.join(buildPath, makeConfig.appName);
    final specsPath = path.join(rpmbuildDirPath, 'SPECS');
    final rpmPath =
        path.join(rpmbuildDirPath, 'RPMS', makeConfig.buildArch ?? 'x86_64');
    final buildWivesDirFile = Directory(buildRoot);
    if (!buildWivesDirFile.existsSync()) {
      buildWivesDirFile.createSync(recursive: true);
    }

    /// copying app files to rpmbuild/BUILD/[appName] directory
    final bundleFiles = appDirectory.listSync();
    for (final file in bundleFiles) {
      await $(
        'cp',
        [
          '-r',
          file.path,
          buildRoot,
        ],
      );
    }

    // fix lib_*_plugin.so rpath
    //
    // more details: https://github.com/flutter/flutter/issues/65400
    final libFiles = Directory(path.join(buildRoot, 'lib')).listSync();
    for (final file in libFiles) {
      if (file is! File) continue;
      if (!file.path.endsWith('.so')) continue;
      // check if points to /home dir
      final processResult = await $(
        'patchelf',
        [
          '--print-rpath',
          file.path,
        ],
      );
      if (processResult.stdout.toString() != ('$ORIGIN')) {
        await $(
          'patchelf',
          [
            '--set-rpath',
            '\$ORIGIN',
            file.path,
          ],
        );
      }
    }

    final iconFile = makeConfig.icon != null
        ? File(path.join(Directory.current.path, makeConfig.icon!))
        : null;

    iconFile?.copy(
      path.join(
        buildPath,
        makeConfig.appName + path.extension(iconFile.path),
      ),
    );

    if (makeConfig.icon != null) {
      final iconFile = File(makeConfig.icon!);
      if (!iconFile.existsSync()) {
        throw MakeError("provided icon ${makeConfig.icon} path wasn't found");
      }
    }

    if (makeConfig.metainfo != null) {
      final metainfoPath =
          path.join(Directory.current.path, makeConfig.metainfo!);
      final metainfoFile = File(metainfoPath);
      if (!metainfoFile.existsSync()) {
        throw MakeError("Metainfo $metainfoPath path doesn't exist");
      }

      await metainfoFile.copy(
        path.join(
          buildPath,
          makeConfig.appBinaryName + path.extension(makeConfig.metainfo!, 2),
        ),
      );
    }

    // create & write the files got from makeConfig
    final specFile = File(path.join(specsPath, '${makeConfig.appName}.spec'));
    final desktopEntryFile =
        File(path.join(buildPath, '${makeConfig.appName}.desktop'));

    if (!specFile.existsSync()) specFile.createSync();
    if (!desktopEntryFile.existsSync()) desktopEntryFile.createSync();

    await specFile.writeAsString(files['SPEC']!);
    await desktopEntryFile.writeAsString(files['DESKTOP']!);

    // make the rpm
    final processResult = await $(
      'rpmbuild',
      [
        '--define',
        '_topdir $rpmbuildDirPath',
        '-bb',
        specFile.path,
      ],
      environment: {'QA_RPATHS': (0x0001 | 0x0010).toString()},
    );

    if (processResult.exitCode != 0) {
      throw MakeError();
    }

    final rpms = Directory(rpmPath).listSync();
    for (var rpm in rpms) {
      if (rpm is! File) continue;
      await $(
        'cp',
        [
          rpm.path,
          makeConfig.outputFile.path,
        ],
      );
      break;
    }
    packagingDirectory.deleteSync(recursive: true);
    return MakeResult(makeConfig);
  }
}
