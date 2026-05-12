import 'dart:io';

void main() {
  final path = 'lib/theme/tokens.dart';
  final file = File(path);
  var content = file.readAsStringSync();
  content = content.replaceAllMapped(RegExp(r'\.withOpacity\((.*?)\)'), (m) => '.withValues(alpha: ${m[1]})');
  file.writeAsStringSync(content);
}
