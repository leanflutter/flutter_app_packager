import 'dart:convert';
import 'dart:io';

import 'package:app_package_maker/app_package_maker.dart';
import 'package:app_package_publisher/app_package_publisher.dart';
import 'package:colorize/colorize.dart';
import 'package:flutter_app_builder/flutter_app_builder.dart';
import 'package:flutter_app_packager/flutter_app_packager.dart';
import 'package:flutter_app_publisher/flutter_app_publisher.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';

import 'distribute_options.dart';
import 'release.dart';
import 'release_job.dart';
import 'utils/logger.dart';
import 'utils/progress_bar.dart';
import 'utils/pub_dev_api.dart';

class FlutterDistributor {
  final FlutterAppBuilder _builder = FlutterAppBuilder();
  final FlutterAppPackager _packager = FlutterAppPackager();
  final FlutterAppPublisher _publisher = FlutterAppPublisher();

  Pubspec? _pubspec;
  Pubspec get pubspec {
    if (_pubspec == null) {
      final yamlString = File('pubspec.yaml').readAsStringSync();
      _pubspec = Pubspec.parse(yamlString);
    }
    return _pubspec!;
  }

  Map<String, String> _environment = {};
  Map<String, String> get environment {
    if (_environment.keys.isEmpty) {
      for (String key in Platform.environment.keys) {
        String? value = Platform.environment[key];
        if ((value ?? '').isNotEmpty) {
          _environment[key] = value!;
        }
      }
      List<String> keys = distributeOptions.env?.keys.toList() ?? [];
      for (String key in keys) {
        String? value = distributeOptions.env?[key];

        if ((value ?? '').isNotEmpty) {
          _environment[key] = value!;
        }
      }
    }
    return _environment;
  }

  DistributeOptions? _distributeOptions;
  DistributeOptions get distributeOptions {
    if (_distributeOptions == null) {
      File file = File('distribute_options.yaml');
      if (file.existsSync()) {
        final yamlString = File('distribute_options.yaml').readAsStringSync();
        final yamlDoc = loadYaml(yamlString);
        _distributeOptions = DistributeOptions.fromJson(
          json.decode(json.encode(yamlDoc)),
        );
      } else {
        _distributeOptions = DistributeOptions(
          output: 'dist/',
          releases: [],
        );
      }
    }
    return _distributeOptions!;
  }

  Future<String?> _getCurrentVersion() async {
    try {
      var scriptFile = Platform.script.toFilePath();
      var pathToPubSpecYaml = p.join(p.dirname(scriptFile), '../pubspec.yaml');
      var pathToPubSpecLock = p.join(p.dirname(scriptFile), '../pubspec.lock');

      var pubSpecYamlFile = File(pathToPubSpecYaml);

      var pubSpecLockFile = File(pathToPubSpecLock);

      if (pubSpecLockFile.existsSync()) {
        var yamlDoc = loadYaml(await pubSpecLockFile.readAsString());
        if (yamlDoc['packages']['flutter_distributor'] == null) {
          var yamlDoc = loadYaml(await pubSpecYamlFile.readAsString());
          return yamlDoc['version'];
        }

        return yamlDoc['packages']['flutter_distributor']['version'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> checkVersion() async {
    String? currentVersion = await _getCurrentVersion();
    String? latestVersion =
        await PubDevApi.getLatestVersionFromPackage('flutter_distributor');

    if (currentVersion != null &&
        latestVersion != null &&
        currentVersion.compareTo(latestVersion) < 0) {
      Colorize msg = Colorize([
        '╔════════════════════════════════════════════════════════════════════════════╗',
        '║ A new version of Flutter Distributor is available!                         ║',
        '║                                                                            ║',
        '║ To update to the latest version, run "flutter_distributor upgrade".        ║',
        '╚════════════════════════════════════════════════════════════════════════════╝',
        '',
      ].join('\n'));
      print(msg.yellow());
    }
    return Future.value();
  }

  Future<String?> getCurrentVersion() async {
    return await _getCurrentVersion();
  }

  Future<List<MakeResult>> package(
    String platform,
    List<String> targets, {
    required bool cleanBeforeBuild,
    required Map<String, dynamic> buildArguments,
    String? jobName,
  }) async {
    List<MakeResult> makeResultList = [];

    try {
      Directory outputDirectory = distributeOptions.outputDirectory;
      if (!outputDirectory.existsSync()) {
        outputDirectory.createSync(recursive: true);
      }

      bool isBuildOnlyOnce = platform != 'android';
      BuildResult? buildResult;

      for (String target in targets) {
        logger.info('Packaging ${pubspec.name} ${pubspec.version} as $target:');
        if (!isBuildOnlyOnce || (isBuildOnlyOnce && buildResult == null)) {
          logger.info('Building...');
          buildResult = await _builder.build(
            platform,
            target,
            cleanBeforeBuild: cleanBeforeBuild,
            buildArguments: buildArguments,
            onProcessStdOut: (data) {
              String message = utf8.decoder.convert(data).trim();
              logger.info(Colorize(message).darkGray());
            },
            onProcessStdErr: (data) {
              String message = utf8.decoder.convert(data).trim();
              logger.info(Colorize(message).darkGray());
            },
          );
          logger.info(
            Colorize('Successfully builded ${buildResult.outputDirectory}')
                .green(),
          );
        }

        if (buildResult != null) {
          MakeResult makeResult = await _packager.package(
            buildResult.outputDirectory,
            outputDirectory: outputDirectory,
            jobName: jobName,
            platform: platform,
            flavor: buildArguments['flavor'],
            target: target,
            onProcessStdOut: (data) {
              String message = utf8.decoder.convert(data).trim();
              logger.info(Colorize(message).darkGray());
            },
            onProcessStdErr: (data) {
              String message = utf8.decoder.convert(data).trim();
              logger.info(Colorize(message).darkGray());
            },
          );

          logger.info(
            Colorize('Successfully packaged ${makeResult.outputFile.path}')
                .green(),
          );

          makeResultList.add(makeResult);
        }
      }
    } on Error catch (error) {
      logger.shout(Colorize(error.toString()).red());
      logger.shout(Colorize(error.stackTrace.toString()).red());
    }

    return makeResultList;
  }

  Future<List<PublishResult>> publish(
    File file,
    List<String> targets, {
    Map<String, dynamic>? publishArguments,
  }) async {
    List<PublishResult> publishResultList = [];
    try {
      for (String target in targets) {
        ProgressBar progressBar = ProgressBar(
          format: 'Publishing to $target: {bar} {value}/{total} {percentage}%',
        );

        Map<String, dynamic>? newPublishArguments = {};

        if (publishArguments != null) {
          for (var key in publishArguments.keys) {
            if (!key.startsWith('$target-')) continue;
            dynamic value = publishArguments[key];

            if (value is List) {
              value = Map.fromIterable(
                value,
                key: (e) => e.split('=')[0],
                value: (e) => e.split('=')[1],
              );
            }

            newPublishArguments.putIfAbsent(
              key.replaceAll('$target-', ''),
              () => value,
            );
          }
        }

        if (newPublishArguments.keys.isEmpty) {
          newPublishArguments = publishArguments;
        }

        PublishResult publishResult = await _publisher.publish(
          file,
          target: target,
          environment: this.environment,
          publishArguments: newPublishArguments,
          onPublishProgress: (sent, total) {
            if (!progressBar.isActive) {
              progressBar.start(total, sent);
            } else {
              progressBar.update(sent);
            }
          },
        );
        if (progressBar.isActive) progressBar.stop();
        logger.info(
          Colorize('Successfully published ${publishResult.url}').green(),
        );

        publishResultList.add(publishResult);
      }
    } on Error catch (error) {
      logger.shout(Colorize(error.toString()).red());
      logger.shout(Colorize(error.stackTrace.toString()).red());
    }
    return publishResultList;
  }

  Future<void> release(
    String name, {
    required List<String> jobNameList,
    required List<String> skipJobNameList,
    required bool cleanBeforeBuild,
  }) async {
    Directory outputDirectory = distributeOptions.outputDirectory;
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    }

    List<Release> releases = [];

    if (name.isNotEmpty) {
      releases =
          distributeOptions.releases.where((e) => e.name == name).toList();
    }

    if (releases.isEmpty) {
      throw Exception('Missing/incomplete `distribute_options.yaml` file.');
    }

    for (Release release in releases) {
      List<ReleaseJob> filteredJobs = release.jobs.where((e) {
        if (jobNameList.isNotEmpty) {
          return jobNameList.contains(e.name);
        }
        if (skipJobNameList.isNotEmpty) {
          return !skipJobNameList.contains(e.name);
        }
        return true;
      }).toList();
      if (filteredJobs.isEmpty) {
        throw Exception('No available jobs found in ${release.name}.');
      }

      bool needCleanBeforeBuild = cleanBeforeBuild;

      for (ReleaseJob job in filteredJobs) {
        List<MakeResult> makeResultList = await package(
          job.package.platform,
          [job.package.target],
          cleanBeforeBuild: needCleanBeforeBuild,
          buildArguments: job.package.buildArgs ?? {},
          jobName: job.name,
        );
        // Clean only once
        needCleanBeforeBuild = false;

        if (job.publish != null || job.publishTo != null) {
          String? publishTarget = job.publishTo ?? job.publish?.target;
          MakeResult makeResult = makeResultList.first;
          await publish(
            makeResult.outputFile,
            [publishTarget!],
            publishArguments: job.publish?.args,
          );
        }
      }
    }
    return Future.value();
  }

  Future<void> upgrade() async {
    Process process = await Process.start(
      'dart',
      ['pub', 'global', 'activate', 'flutter_distributor'],
    );
    process.stdout.listen((event) {
      String msg = utf8.decoder.convert(event).trim();
      logger.info(msg);
    });
    process.stderr.listen((event) {
      String msg = utf8.decoder.convert(event).trim();
      logger.shout(msg);
    });

    return Future.value();
  }
}
