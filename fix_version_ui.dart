import 'dart:io';

void main() {
  final file = File('lib/screens/settings_screen.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    "subtitle: Text('\${strings.version} 1.0.2 (Build 3)'),",
    "subtitle: const Text('Wersja 1.0.3 Beta (Build 4)'), // TODO: W przyszłości użyj package_info_plus"
  );

  file.writeAsStringSync(content);
  print('Done!');
}
