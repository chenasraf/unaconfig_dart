/// A library for searching for configuration files.
library unaconfig;

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:yaml/yaml.dart';

/// A parser for searching for a configuration.
/// The [pattern] is used to match against the file name.
/// The [getConfig] function is used to parse the configuration file contents.
/// The [fs] is the file system to use to read the configuration file (defaults to the local file system).
class ConfigParser {
  /// The regular expression to match against the file name.
  final Pattern pattern;

  /// The function to use to parse the configuration file contents.
  final FutureOr<Map<String, dynamic>?> Function(
    String name,
    String path,
    String contents,
  ) getConfig;

  /// The file system to use to read the configuration file.
  final FileSystem fs;

  const ConfigParser(
    this.pattern,
    this.getConfig, {
    this.fs = const LocalFileSystem(),
  });

  /// Whether the parser matches the file name.
  bool matches(String path) => pattern.allMatches(path).isNotEmpty;

  /// Search for the configuration in the file at [path].
  Future<Map<String, dynamic>?> search(String name, String path) async {
    try {
      final contents = await fs.file(path).readAsString();
      return getConfig(name, path, contents);
    } catch (e) {
      // ignore: avoid_print
      print('Error reading $path: $e');
      return null;
    }
  }

  /// Create a copy of the parser with the given parameters.
  ConfigParser copyWith({
    Pattern? pattern,
    FutureOr<Map<String, dynamic>?> Function(
            String name, String path, String contents)?
        getConfig,
    FileSystem? fs,
  }) {
    return ConfigParser(
      pattern ?? this.pattern,
      getConfig ?? this.getConfig,
      fs: fs ?? this.fs,
    );
  }

  /// Convert a YAML map to a native (Dart) map.
  static Map<String, dynamic> yamlMapToMap(YamlMap yaml) {
    final json = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is YamlMap) {
        json[key] = yamlMapToMap(value);
      } else if (value is YamlList) {
        json[key] = value.toList();
      } else {
        json[key] = value;
      }
    }
    return json;
  }

  /// Load a YAML string as a native (Dart) map. Returns an empty map if the YAML is invalid.
  static Map<String, dynamic> loadYamlAsMap(String contents) {
    final map = loadYaml(contents);
    if (map is YamlMap) {
      return yamlMapToMap(map);
    }
    return {};
  }
}

