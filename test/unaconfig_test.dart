import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unaconfig/unaconfig.dart';

void main() {
  test('basic json', () async {
    final fs = MemoryFileSystem();
    fs.file(p.join(fs.currentDirectory.path, '.test.json')).writeAsStringSync(
          json.encode({
            'test': {'key': 'value'}
          }),
        );

    final explorer = ConfigExplorer('test', fs: fs);
    final results = await explorer.search();
    expect(results, {
      'test': {'key': 'value'}
    });
  });

  test('basic yaml', () async {
    final fs = MemoryFileSystem();
    fs
        .file('${fs.currentDirectory.path}/.test.yaml')
        .writeAsStringSync('''test:\n  key: value''');

    final explorer = ConfigExplorer('test', fs: fs);
    final results = await explorer.search();
    expect(results, {
      'test': {'key': 'value'}
    });
  });
}

