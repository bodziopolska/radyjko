import 'dart:io';

void main() {
  final file = File('android/app/build.gradle.kts');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    '    buildTypes {\r\n        release {\r\n            signingConfig = signingConfigs.getByName("release")\r\n        }\r\n    }',
    '    buildTypes {\r\n        release {\r\n            signingConfig = signingConfigs.getByName("release")\r\n            isMinifyEnabled = true\r\n            isShrinkResources = true\r\n            proguardFiles(\r\n                getDefaultProguardFile("proguard-android-optimize.txt"),\r\n                "proguard-rules.pro"\r\n            )\r\n        }\r\n    }',
  );

  file.writeAsStringSync(content);
  print('Done!');
}
