// ignore_for_file: avoid_print

import 'package:unaconfig/unaconfig.dart';

final explorer = ConfigExplorer('test_pkg');

void main() async {
  final config = await explorer.search();
  print(config);
}
