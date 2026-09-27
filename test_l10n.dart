import 'dart:io';
void main() {
  final file = File('lib/l10n/app_strings.dart');
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    if (line.contains('tryChangingFilters')) {
      print(line);
    }
  }
}
