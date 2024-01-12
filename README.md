# unaconfig

If you are bulding a package or library for dart, you will often need to get the user config from
either a standalone file or pubspec.yaml.

This package lets you find files in various formats and get the first (or merged) config that
matches.

## Features

- Just set your config name and search
- Customizable strategies, so any file type can be supported
- Default strategies for key under `pubspec.yaml`

## Getting started

Install into your dependencies using pub:

```bash
dart pub add unaconfig
```

## Usage

### Basic Usage

Create an explorer and search:

```dart
final config = await ConfigExplorer('my_package').search();
```

### Providing paths and options

You can provide several parameters to the `ConfigExplorer` to change where and how it searches for
files.

Only the first parameter, `name`, is required. Below are the default values:

```dart
final explorer = ConfigExplorer('my_package',
  paths: [Directory.current],
  // see "Search Patterns" section
  searchPatterns: ConfigExplorer.defaultSearchPatterns,
  // see "Strategies" section
  strategies: ConfigExplorer.defaultStrategies,
  merge: true,
  fs: LocalFileSystem(),
);
```

## Search Patterns

Search patterns define what the config file should be named, inside any of the paths in the `paths`
list.

- Each string will eventually become a `RegExp` pattern, so be sure to escape as necessary.
- `{name}` inside the patterns is replaced by the name provided to the `ConfigExplorer`.

By default, these are the files being searched:

```dart
final defaultSearchPatterns = <String>[
  r'^pubspec\.yaml$',
  r'.{name}\.json$',
  r'.{name}\.ya?ml$',
];
```

## Strategies

A strategy defines that once a file has been found to match one of the search patterns, how to parse
its content into a `Map<String, dynamic>`.

Each strategy takes a pattern, which is tested against the file name to decide that this strategy
will be used on it.

It also takes a function, which given the config name, path and string contents should return a
`Map<String, dynamic>` which represents the config that you want to load.

For example, this is the `json` `SearchStrategy`, you can use this example to implement your own:

```dart
SearchStrategy(
  RegExp(r'.*\.json$'),
  (name, path, contents) => json.decode(contents),
)
```

The current strategies are:

- `pubspec.yaml` - Fetches the `name` from the config, and only loads that subsection of the map
- Any `yaml` file - parse yaml file entirely
- Any `json` file - parse json file entirely

You can create your own strategies easily by implementing an instance of this class (or extend to a
subclass) and putting it in the `strategies` parameter of `ConfigExplorer`.

**Note:** if you supply your own strategies, they will replace the defaults. Make sure to include
them manually from `ConfigExplorer.defaultStrategies` if you so desire.

## Contributing

I am developing this package on my free time, so any support, whether code, issues, or just stars is
very helpful to sustaining its life. If you are feeling incredibly generous and would like to donate
just a small amount to help sustain this project, I would be very very thankful!

<a href='https://ko-fi.com/casraf' target='_blank'>
  <img height='36' style='border:0px;height:36px;'
    src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
    alt='Buy Me a Coffee at ko-fi.com' />
</a>

I welcome any issues or pull requests on GitHub. If you find a bug, or would like a new feature,
don't hesitate to open an appropriate issue and I will do my best to reply promptly.
