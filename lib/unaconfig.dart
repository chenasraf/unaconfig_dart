library unaconfig;

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

/// This class is used to search for configuration files in a directory or directories.
///
/// The [name] is used to search for files with the name in the path, according to the
/// [searchPatterns]. The [searchPatterns] are regular expressions that are matched against
/// the file name. The [paths] are the directories to search. If [paths] is null, the current
/// directory is searched.
///
/// The [strategies] are used to search for the configuration file contents. The [strategies]
/// are tried in order, and the first one that matches is used. If [strategies] is null, the
/// default strategies are used. The default strategies are:
///
/// * If the file name matches `^pubspec\.yaml$`, the file is parsed as YAML and the [name]
///   is used as the key to look up the configuration.
/// * If the file name matches `.*\.json$`, the file is parsed as JSON.
/// * If the file name matches `.*\.ya?ml$`, the file is parsed as YAML.
class ConfigExplorer {
  /// The name of the configuration to search for.
  final String name;

  /// The paths to search for the configuration.
  final List<String>? paths;

  /// The regular expressions to match against the file name.
  final List<String>? searchPatterns;

  /// The strategies to use to search for the configuration.
  final List<SearchStrategy>? strategies;

  /// Whether to merge the results from multiple configuration files.
  /// If false, the results from the last configuration file found are used.
  /// If true, the results from all configuration files found are merged.
  ///
  /// The default is `true`.
  final bool merge;

  /// The file system to use to search for the configuration.
  final FileSystem fs;

  /// The default search patterns.
  static final defaultSearchPatterns = <String>[
    r'^pubspec\.yaml$',
    r'.{name}\.json$',
    r'.{name}\.ya?ml$',
  ];

  /// The default strategies.
  static final defaultStrategies = <SearchStrategy>[
    SearchStrategy(
      RegExp(r'^pubspec\.yaml$'),
      (name, path, contents) {
        final map = _loadYamlAsJson(contents);
        if (map.containsKey(name)) {
          return map;
        }
        return null;
      },
    ),
    SearchStrategy(
      RegExp(r'.*\.json$'),
      (name, path, contents) => json.decode(contents),
    ),
    SearchStrategy(
      RegExp(r'.*\.ya?ml$'),
      (name, path, contents) => _loadYamlAsJson(contents),
    ),
  ];

  ConfigExplorer(
    this.name, {
    this.paths,
    this.searchPatterns,
    this.merge = true,
    this.strategies,
    this.fs = const LocalFileSystem(),
  });

  /// Search for the configuration.
  /// Returns the configuration as a map, or null if no configuration was found.
  Future<Map<String, dynamic>?> search() async {
    final results = <String, dynamic>{};
    final strategies = (this.strategies ?? defaultStrategies)
        .map((s) => s.copyWith(fs: fs))
        .toList();
    final patterns = (searchPatterns ?? defaultSearchPatterns)
        .map((p) => p.replaceAll('{name}', name))
        .toList();
    for (final pathname in paths ?? [fs.currentDirectory.path]) {
      final dirPath = p.isRelative(pathname) ? p.absolute(pathname) : pathname;
      final dir = fs.directory(dirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final path = entity.path;
            final fullPath = p.join(dirPath, path);
            if (patterns.any((p) => RegExp(p).allMatches(path).isNotEmpty)) {
              for (final strategy in strategies) {
                if (strategy.matches(path)) {
                  final config = await strategy.search(name, fullPath);
                  if (config != null) {
                    if (!merge) {
                      results.clear();
                    }
                    results.addAll(config);
                  }
                }
              }
            }
          }
        }
      }
    }
    if (results.isEmpty) {
      return null;
    }
    return results;
  }
}

/// A strategy for searching for a configuration.
/// The [pattern] is used to match against the file name.
/// The [getConfig] function is used to parse the configuration file contents.
/// The [fs] is the file system to use to read the configuration file (defaults to the local file system).
class SearchStrategy {
  /// The regular expression to match against the file name.
  final Pattern pattern;

  /// The function to use to parse the configuration file contents.
  final FutureOr<Map<String, dynamic>?> Function(
      String name, String path, String contents) getConfig;

  /// The file system to use to read the configuration file.
  final FileSystem fs;

  const SearchStrategy(
    this.pattern,
    this.getConfig, {
    this.fs = const LocalFileSystem(),
  });

  /// Whether the strategy matches the file name.
  bool matches(String path) => pattern.allMatches(path).isNotEmpty;

  /// Search for the configuration in the file at [path].
  Future<Map<String, dynamic>?> search(String name, String path) async {
    try {
      final contents = await fs.file(path).readAsString();
      return getConfig(name, path, contents);
    } catch (e) {
      print('Error reading $path: $e');
      return null;
    }
  }

  SearchStrategy copyWith({
    Pattern? pattern,
    FutureOr<Map<String, dynamic>?> Function(
            String name, String path, String contents)?
        getConfig,
    FileSystem? fs,
  }) {
    return SearchStrategy(
      pattern ?? this.pattern,
      getConfig ?? this.getConfig,
      fs: fs ?? this.fs,
    );
  }
}

Map<String, dynamic> _yamlToJson(YamlMap yaml) {
  final json = <String, dynamic>{};
  for (final entry in yaml.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is YamlMap) {
      json[key] = _yamlToJson(value);
    } else if (value is YamlList) {
      json[key] = value.toList();
    } else {
      json[key] = value;
    }
  }
  return json;
}

Map<String, dynamic> _loadYamlAsJson(String contents) {
  final map = loadYaml(contents);
  if (map is YamlMap) {
    return _yamlToJson(map);
  }
  return {};
}
