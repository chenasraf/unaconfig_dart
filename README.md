# unaconfig

If you are bulding a package or library for dart, you will often need to get the user config from
either a standalone file or pubspec.yaml.

Unaconfig lets you find files in various formats and get the first config that matches.

## Features

- Just set your config name and search
- Customizable parsers, so any file type can be supported
- Default parsers for key under `pubspec.yaml`
- Fully customizable

## Getting started

Install into your dependencies using pub:

```bash
dart pub add unaconfig
```

## Usage

### Basic Usage

Create an explorer and search:

```dart
final config = await Unaconfig('my_package').search();
```

### Providing paths and options

You can provide several parameters to the `Unaconfig` to change where and how it searches for files.

Only the first parameter, `name`, is required. Below are the default values:

```dart
final explorer = Unaconfig(
  // Name to look for in filenames
  'my_package',
  // Paths to search in, see "Paths" section
  paths: [currentDirectory, projectRoot, homeDirectory],
  // Filenames to try in each search path, see "Filename Patterns" section
  filenamePatterns: Unaconfig.defaultFilenamePatterns,
  // Parsers that resolve config files, see "ConfigParsers" section
  parsers: Unaconfig.defaultParsers,
  // The filesystem to use for file searching. Can be overridden for tests, or using alternative
  // filesystems.
  fs: LocalFileSystem(),
);
```

## Paths

Unaconfig searches in several directories, matching on the first matched file & config.

By default, the following directories are tried, in order:

- The current directory
- The project root (closest dir to current that contains `pubspec.yaml`)
- The user's home dir

Patterns with paths containing directories in the `filenamePatterns` field can be triggered for the
provided directories inside any of the above or provided paths. For example, `.config/{name}.yaml`
will also try to use both `<projectRoot>/.config/{name}.yaml` and `$HOME/.config/{name}.yaml`,
returning the first successful match.

## Filename Patterns

Filename patterns patterns define what files to look for in each searched directory.

- Each string will eventually become a `RegExp` pattern, so be sure to escape as necessary.
- `{name}` inside the patterns is replaced by the name provided to the `Unaconfig`.

A successful match will start going through the ConfigParsers until a config map is returned from
it.

By default, Unaconfig checks the for the following config files in every matched dir:

- A property in `pubspec.yaml`
- `{name}.yaml`
- `{name}.json`
- `.{name}.yaml`
- `.{name}.json`
- `.config/{name}.yaml`
- `.config/{name}.json`

## ConfigParsers

A config parser takes the file and its contents, along with the name to lookup, and produces a final
config map.

Each parser takes a pattern, which is tested against the file name to decide that this parser will
be used on it.

It also takes a function, which given the config name, path and string contents should return a
`Map<String, dynamic>` which represents the config that you want to load.

For example, this is the `ConfigParser` for `json` files, you can use this example to implement your
own:

```dart
ConfigParser(
  RegExp(r'.*\.json$'),
  (name, path, contents) => json.decode(contents),
)
```

The current parsers are:

- `pubspec.yaml` - Fetches the `name` from the config, and only loads that subsection of the map
- Any `yaml` file - parse yaml file entirely
- Any `json` file - parse json file entirely

You can create your own parsers easily by implementing an instance of this class (or extend to a
subclass) and putting it in the `parsers` parameter of `Unaconfig`.

**Note:** if you supply your own parsers, they will replace the defaults. Make sure to include them
manually from `Unaconfig.defaultparsers` if you so desire.

## Notes

The package is inspired by [cosmiconfig](https://www.npmjs.com/package/cosmiconfig) and follows
similar, but not identical, conventions. It is not aimed to reach full symmetry, as the NPM and Dart
ecosystems are different (for example, `.dart` files cannot be dynamically loaded, and `.{name}rc`
files are not usually used in the Dart/Pub ecosystem). However, you are free to implement your own
ConfigParsers, paths and name patterns to modify the behaviors as you wish.

## Contributing

I am developing this package on my free time, so any support, whether code, issues, or just stars is
very helpful to sustaining its life. If you are feeling incredibly generous and would like to donate
just a small amount to help sustain this project, I would be very very thankful!

<a href="https://ko-fi.com/casraf" target="_blank">
  <img height="36"
    src="https://cdn.ko-fi.com/cdn/kofi1.png?v=3"
    alt="Buy Me a Coffee at ko-fi.com" />
</a>

I welcome any issues or pull requests on GitHub. If you find a bug, or would like a new feature,
don't hesitate to open an appropriate issue and I will do my best to reply promptly.
