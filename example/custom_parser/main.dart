// ignore_for_file: avoid_print

import 'package:unaconfig/unaconfig.dart';

final explorer = Unaconfig(
  'test_pkg',
  filenamePatterns: [
    ...Unaconfig.defaultFilenamePatterns,
    r'.{name}\.txt$',
  ],
  parsers: [
    ...Unaconfig.defaultParsers,
    ConfigParser(
      RegExp(r'^.+\.txt$'),
      (name, path, contents) => {'text': contents},
    ),
  ],
);

void main() async {
  final config = await explorer.search();
  print(config);
}
