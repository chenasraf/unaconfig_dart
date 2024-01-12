// ignore_for_file: avoid_print

import 'package:unaconfig/unaconfig.dart';

final explorer = ConfigExplorer(
  'test_pkg',
  searchPatterns: [
    ...ConfigExplorer.defaultSearchPatterns,
    r'.{name}\.txt$',
  ],
  strategies: [
    ...ConfigExplorer.defaultStrategies,
    SearchStrategy(
      RegExp(r'^.+\.txt$'),
      (name, path, contents) => {'text': contents},
    ),
  ],
);

void main() async {
  final config = await explorer.search();
  print(config);
}

