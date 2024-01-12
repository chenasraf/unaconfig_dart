// ignore_for_file: avoid_print

import 'package:unaconfig/unaconfig.dart';

final explorer = Unaconfig(
  'test_pkg',
  searchPatterns: [
    ...Unaconfig.defaultSearchPatterns,
    r'.{name}\.txt$',
  ],
  strategies: [
    ...Unaconfig.defaultStrategies,
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

