import 'dart:io';

import 'app_builder.dart';

class AppBuilderIos extends AppBuilder {
  @override
  String get platform => 'ios';

  @override
  String get buildSubcommand => 'ipa';

  @override
  bool get isSupportedOnCurrentPlatform => Platform.isMacOS;

  @override
  Future<BuildResult> build({
    String? target,
    required Map<String, dynamic> buildArguments,
  }) {
    return super.build(
      target: target,
      buildArguments: buildArguments,
    );
  }

  @override
  Directory get outputDirectory {
    return Directory('build/ios/ipa');
  }
}
