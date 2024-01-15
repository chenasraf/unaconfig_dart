import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;

import 'config_parser.dart';

/// This class is used to search for configuration files in a directory or directories.
///
/// The [name] is used to search for files with the name in the path, according to the
/// [filenamePatterns]. The [filenamePatterns] are regular expressions that are matched against
/// the file name. The [paths] are the directories to search. If [paths] is null, the current
/// directory is searched.
///
/// The [parsers] are used to search for the configuration file contents. The [parsers]
/// are tried in order, and the first one that matches is used. If [parsers] is null, the
/// default parsers are used. The default parsers are:
///
/// * If the file name matches `^pubspec\.yaml$`, the file is parsed as YAML and the [name]
///   is used as the key to look up the configuration.
/// * If the file name matches `.*\.json$`, the file is parsed as JSON.
/// * If the file name matches `.*\.ya?ml$`, the file is parsed as YAML.
class Unaconfig {
  /// The name of the configuration to search for.
  final String name;

  /// The paths to search for the configuration.
  final List<String> paths;

  /// The regular expressions to match against the file name.
  final List<String> filenamePatterns;

  /// The parsers to use to search for the configuration.
  final List<ConfigParser> parsers;

  /// The file system to use to search for the configuration.
  final FileSystem fs;

  Unaconfig(
    this.name, {
    List<String>? paths,
    List<String>? filenamePatterns,
    List<ConfigParser>? parsers,
    this.fs = const LocalFileSystem(),
  })  : paths = paths ?? [getProjectRoot(fs), getHomeDirectory(fs)],
        filenamePatterns = filenamePatterns ?? defaultFilenamePatterns,
        parsers = parsers ?? defaultParsers;

  /// The default search patterns.
  static final defaultFilenamePatterns = <String>[
    r'pubspec\.yaml$',
    r'.{name}\.json$',
    r'.{name}\.ya?ml$',
    r'\.config\/{name}.json$',
    r'\.config\/{name}.ya?ml$',
  ];

  /// The default parsers.
  static final defaultParsers = <ConfigParser>[
    ConfigParser(
      RegExp(r'^pubspec\.yaml$'),
      (name, path, contents) {
        final map = ConfigParser.loadYamlAsMap(contents);
        if (map.containsKey(name)) {
          return map[name];
        }
        return null;
      },
    ),
    ConfigParser(
      RegExp(r'\.json$'),
      (name, path, contents) => json.decode(contents),
    ),
    ConfigParser(
      RegExp(r'\.ya?ml$'),
      (name, path, contents) => ConfigParser.loadYamlAsMap(contents),
    ),
  ];

  /// This searches for the project root directory, and falls back to the
  /// current directory if no project root is found.
  ///
  /// See [getProjectRoot].
  String get projectRoot => getProjectRoot(fs);

  /// The default home directory of the current user.
  String get homeDirectory => getHomeDirectory(fs);

  /// Get the project root directory. The [fs] is the file system to use to search for the project root.
  ///
  /// The project root is the directory that contains a `pubspec.yaml` file.
  /// If no project root is found, the current directory is used.
  static String getProjectRoot(FileSystem fs) {
    var dir = fs.currentDirectory;
    while (true) {
      if (dir.childFile('pubspec.yaml').existsSync()) {
        return dir.path;
      }
      if (dir.parent.path == dir.path) {
        return fs.currentDirectory.path;
      }
      dir = dir.parent;
    }
  }

  /// Get the home directory. The [fs] is the file system to use to search for the home directory.
  static String getHomeDirectory(FileSystem fs) {
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'];
    return home ?? fs.currentDirectory.path;
  }

  /// Search for the configuration.
  ///
  /// Returns the configuration as a map, or null if no configuration was found.
  Future<Map<String, dynamic>?> search() async {
    final path = await findConfig();
    if (path == null) {
      return null;
    }
    final parsers = this.parsers.map((s) => s.copyWith(fs: fs));
    for (final parser in parsers) {
      final filename = p.basename(path);
      if (!parser.matches(filename)) {
        continue;
      }
      final config = await parser.search(name, path);
      if (config == null) {
        continue;
      }
      return config;
    }
    return null;
  }

  /// Search for the configuration file.
  ///
  /// Returns the path to the configuration file, or null if no configuration was found.
  Future<String?> findConfig() async {
    final parsers = this.parsers.map((s) => s.copyWith(fs: fs)).toList();
    final patterns = filenamePatterns
        .map((p) => RegExp(p.replaceAll('{name}', name)))
        .toList();
    final searchPaths = paths;

    for (final pathname in searchPaths) {
      final dirPath = p.isRelative(pathname) ? p.absolute(pathname) : pathname;
      final dir = fs.directory(dirPath);
      final dirExists = await dir.exists();
      if (!dirExists) {
        continue;
      }
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        final path = entity.path;
        final filename = p.basename(path);
        final isPathInPatterns = patterns.any((regex) =>
            regex.allMatches(path).isNotEmpty ||
            regex.allMatches(filename).isNotEmpty);
        if (!isPathInPatterns) {
          continue;
        }

        for (final parser in parsers) {
          if (!parser.matches(filename)) {
            continue;
          }
          final config = await parser.search(name, path);
          if (config == null) {
            continue;
          }
          return path;
        }
      }
    }
    return null;
  }
}
