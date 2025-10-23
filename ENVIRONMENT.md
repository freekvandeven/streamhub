# Environment Variables Guide````markdown

# Environment Variables Guide

This project uses `flutter_dotenv` and `environment_config` to manage environment variables securely.

This project uses `flutter_dotenv` and `environment_config` to manage environment variables securely.

## 📋 Overview

## 📋 Overview

- **flutter_dotenv**: Loads environment variables from `dotenv` files at runtime

- **environment_config**: Generates type-safe environment configurations and example dotenv files- **flutter_dotenv**: Loads environment variables from `dotenv` files at runtime

- **environment_config**: Generates type-safe environment configurations and example dotenv files

## 🚀 Quick Start

## 🚀 Quick Start

### 1. Create Your Environment File

### 1. Create Your Environment File

Create a `dotenv` file in the project root:

Create a `dotenv` file in the project root:

```bash

# Create the file```bash

touch dotenv# Create the file

```touch dotenv

```

Then edit `dotenv` and add your M3U playlist URL:

Then edit `dotenv` and add your M3U playlist URL:

```env
PLAYLIST_URL=http://example.com/playlist.m3u
```

**Note**: Use non-hidden files (`dotenv` instead of `.dotenv`) to ensure they work with Firebase Hosting.

**Note**: Use non-hidden files (`dotenv` instead of `.dotenv`) to ensure they work with Firebase Hosting.

### 2. Generate Example Template (Optional)

### 2. Generate Example Template (Optional)

Use `environment_config` to generate an example file on-the-go:

Use `environment_config` to generate an example file on-the-go:

```bash

dart run environment_config:generate```bash

```dart run environment_config:generate

```

This creates an example template that other developers can reference without checking it into version control.

This creates an example template that other developers can reference without checking it into version control.

### 3. Run the App

The app will automatically load your playlist URL as the default value in the input field:

The app will automatically load your playlist URL as the default value in the input field:

```bash

```bashflutter run

flutter run```

```

## 📁 Environment Files

## 📁 Environment Files

### Available Files

### Available Files

- **`dotenv`** - Default environment (not committed to git)

- **`dotenv`** - Default environment (not committed to git)

- **`dotenv.dev`** - Development environment (not committed to git)**Note**: All `*dotenv*` files are git-ignored to protect credentials.

- **`dotenv.prod`** - Production environment (not committed to git)



**Note**: All `dotenv*` files are git-ignored to protect credentials.

## 🔧 Using environment_config

### Loading Different Environments

The `environment_config` package can generate type-safe environment configurations and example files from your `dotenv` files.

You can load different environment files in `main.dart`:

### Step 1: Create Config File

```dart

// Load defaultCreate `lib/config/env_config.dart`:

await dotenv.load(fileName: "dotenv");

```dart

// Load developmentimport 'package:environment_config/environment_config.dart';

await dotenv.load(fileName: "dotenv.dev");

@DotEnvGen(

// Load production  filename: 'dotenv',

await dotenv.load(fileName: "dotenv.prod");  fieldRename: FieldRename.screamingSnake,

```  includeIfNull: false,

)

## 🔧 Using environment_configabstract class Env {

  const Env();

  /// M3U Playlist URL
  String get playlistUrl;
}

Create `lib/config/env_config.dart`:```



```dart### Step 2: Generate Configuration

import 'package:environment_config/environment_config.dart';

Run the build_runner to generate the configuration:

@DotEnvGen(

  filename: 'dotenv',```bash

  fieldRename: FieldRename.screamingSnake,# One-time generation

  includeIfNull: false,dart run environment_config:generate

)

abstract class Env {# Or watch mode

  const Env();dart run environment_config:generate --watch

```

  /// M3U Playlist URL

  String get playlistUrl;This will generate a `lib/config/env_config.g.dart` file with:

}- Type-safe access to environment variables

```- Validation that required fields exist

- Auto-completion in your IDE

### Step 2: Generate Configuration

### Step 3: Use Generated Config

Run the build_runner to generate the configuration:

```dart
```dart
import 'package:streamhub/config/env_config.g.dart';

// Access your environment variables type-safely
final playlistUrl = Env().playlistUrl;
```

# Or watch mode```

dart run environment_config:generate --watch

```## 🔐 Security



This will generate a `lib/config/env_config.g.dart` file with:### What's Ignored by Git

- Type-safe access to environment variables

- Validation that required fields existAll files matching `dotenv*` are ignored:

- Auto-completion in your IDE

```gitignore

### Step 3: Use Generated Config*dotenv*

```

```dart

import 'package:streamhub/config/env_config.g.dart';This means:

- ✅ `dotenv` - Ignored (safe)

// Access your environment variables type-safely- ✅ `dotenv.dev` - Ignored (safe)

final playlistUrl = Env().playlistUrl;- ✅ `dotenv.prod` - Ignored (safe)

```- ✅ `dotenv.backup` - Ignored (safe)



## 🔐 Security### Why Non-Hidden Files?



### What's Ignored by GitWe use `dotenv` instead of `.dotenv` (non-hidden files) because:

- **Firebase Hosting Compatibility**: Hidden files (starting with `.`) are not uploaded to Firebase

All files matching `dotenv*` are ignored:- **Better Visibility**: Easier to see and manage environment files

- **Consistent Naming**: Works across all platforms without special handling

```gitignore

dotenv*### Best Practices

```

1. **Never commit actual credentials** - All dotenv files are git-ignored

This means:2. **Use different files for different environments** - Separate dev/staging/production

- ✅ `dotenv` - Ignored (safe)3. **Generate examples on-demand** - Use `environment_config:generate` instead of committing example files

- ✅ `dotenv.dev` - Ignored (safe)4. **Keep credentials local** - Each developer creates their own `dotenv`

- ✅ `dotenv.prod` - Ignored (safe)

- ✅ `dotenv.backup` - Ignored (safe)## 📝 Available Variables



### Why Non-Hidden Files?### Current Variables



We use `dotenv` instead of `.dotenv` (non-hidden files) because:

- **Firebase Hosting Compatibility**: Hidden files (starting with `.`) are not uploaded to Firebase
- **Better Visibility**: Easier to see and manage environment files
- **Consistent Naming**: Works across all platforms without special handling

### Best Practices

1. Add to your local `dotenv`:

1. **Never commit actual credentials** - All dotenv files are git-ignored```env

2. **Use different files for different environments** - Separate dev/staging/productionNEW_VARIABLE=actual_value

3. **Generate examples on-demand** - Use `environment_config:generate` instead of committing example files```

4. **Keep credentials local** - Each developer creates their own `dotenv`

2. Access in code:

## 📝 Available Variables```dart

final value = dotenv.env['NEW_VARIABLE'] ?? 'fallback';

### Current Variables```



| Variable | Description | Example |3. (Optional) Share with team by running:

|----------|-------------|---------|```bash

| `PLAYLIST_URL` | Your M3U playlist URL | `http://your-service.com/playlist.m3u` |dart run environment_config:generate

```

### Supported Playlist SourcesThis generates an example file other developers can reference.



StreamHub works with any M3U playlist from legitimate sources:## 🛠️ Troubleshooting



- **Self-hosted media servers**: Plex, Jellyfin, Emby### Error: "Unable to load asset dotenv"

- **Streaming services with M3U export**: Legal streaming platforms

- **Radio stations**: Internet radio M3U playlists**Solution**: Make sure `dotenv` file exists in the project root:

- **Podcasts**: Podcast feeds in M3U format```bash

- **Personal media libraries**: Your own content served via HTTPtouch dotenv

# Then add your variables

### Adding New Variables```



1. Add to your local `dotenv`:### Error: "Variable not found"

```env

NEW_VARIABLE=actual_value**Solution**: Check that the variable is defined in your `dotenv` file and use a fallback:

``````dart

final value = dotenv.env['MY_VAR'] ?? 'default';

2. Access in code:```

```dart

final value = dotenv.env['NEW_VARIABLE'] ?? 'default';### Environment not loading

```

**Solution**: Ensure `dotenv.load()` is called before `runApp()` in `main.dart`:

3. (Optional) Share with team by running:```dart

```bashFuture<void> main() async {

dart run environment_config:generate  await dotenv.load(fileName: "dotenv");

```  runApp(MyApp());

This generates an example file other developers can reference.}

```

## 🛠️ Troubleshooting

## 📚 Further Reading

### Error: "Unable to load asset dotenv"

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)

**Solution**: Make sure `dotenv` file exists in the project root:- [environment_config Documentation](https://pub.dev/packages/environment_config)

```bash- [12-Factor App Methodology](https://12factor.net/config)

touch dotenv

# Then add your variables## 🔄 Switching Between Environments

```

### Option 1: Manual (Current Implementation)

### Error: "Variable not found"

Edit `lib/main.dart` to load different files:

**Solution**: Check that the variable is defined in your `dotenv` file and use a fallback:

```dart```dart

final value = dotenv.env['MY_VAR'] ?? 'default';// For development

```await dotenv.load(fileName: "dotenv.dev");



### Environment not loading// For production

await dotenv.load(fileName: "dotenv.prod");

**Solution**: Ensure `dotenv.load()` is called before `runApp()` in `main.dart`:```

```dart

Future<void> main() async {### Option 2: Build Flavors (Advanced)

  await dotenv.load(fileName: "dotenv");

  runApp(MyApp());Use Flutter flavors to automatically load the right environment:

}

``````dart

const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

## 📚 Further Readingawait dotenv.load(fileName: "dotenv.$flavor");

```

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)

- [environment_config Documentation](https://pub.dev/packages/environment_config)Then run:

- [12-Factor App Methodology](https://12factor.net/config)```bash

flutter run --dart-define=FLAVOR=dev

## 🔄 Switching Between Environmentsflutter run --dart-define=FLAVOR=prod

```

### Option 1: Manual (Current Implementation)

## 💡 Tips

Edit `lib/main.dart` to load different files:

1. **Use descriptive variable names** - Follow the convention: `CATEGORY_SPECIFIC_NAME`

```dart2. **Document each variable** - Add comments in `.dotenv.example`

// For development3. **Validate on startup** - Check critical variables exist before running the app

await dotenv.load(fileName: "dotenv.dev");4. **Never log credentials** - Be careful with debug logging

5. **Rotate credentials regularly** - Change passwords/tokens periodically

// For production
await dotenv.load(fileName: "dotenv.prod");
```

### Option 2: Build Flavors (Advanced)

Use Flutter flavors to automatically load the right environment:

```dart
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
await dotenv.load(fileName: "dotenv.$flavor");
```

Then run:
```bash
flutter run --dart-define=FLAVOR=dev
flutter run --dart-define=FLAVOR=prod
```

## 💡 Tips

1. **Use descriptive variable names** - Follow the convention: `CATEGORY_SPECIFIC_NAME`
2. **Document each variable** - Add comments in your local dotenv file
3. **Validate on startup** - Check critical variables exist before running the app
4. **Never log credentials** - Be careful with debug logging
5. **Rotate credentials regularly** - Change passwords/tokens periodically

## ⚖️ Legal Notice

**StreamHub is designed for streaming legal content only.** The app is a generic M3U playlist player similar to VLC Media Player. It does not provide, host, or facilitate access to any content. Users are solely responsible for ensuring they have the legal right to stream any content they access through this application.
