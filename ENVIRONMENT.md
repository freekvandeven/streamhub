````markdown
# Environment Variables Guide

This project uses `flutter_dotenv` and `environment_config` to manage environment variables securely.

## 📋 Overview

- **flutter_dotenv**: Loads environment variables from `dotenv` files at runtime
- **environment_config**: Generates type-safe environment configurations and example dotenv files

## 🚀 Quick Start

### 1. Create Your Environment File

Create a `dotenv` file in the project root:

```bash
# Create the file
touch dotenv
```

Then edit `dotenv` and add your IPTV playlist URL:

```env
IPTV_PLAYLIST_URL=http://odm391.xyz/get.php?username=3QTW6UP&password=5R1E428&type=m3u&output=mpegts
```

**Note**: Use non-hidden files (`dotenv` instead of `.dotenv`) to ensure they work with Firebase Hosting.

### 2. Generate Example Template (Optional)

Use `environment_config` to generate an example file on-the-go:

```bash
dart run environment_config:generate
```

This creates an example template that other developers can reference without checking it into version control.

The app will automatically load your playlist URL as the default value in the input field:

```bash
flutter run
```

## 📁 Environment Files

### Available Files

- **`dotenv`** - Default environment (not committed to git)

**Note**: All `*dotenv*` files are git-ignored to protect credentials.



## 🔧 Using environment_config

The `environment_config` package can generate type-safe environment configurations and example files from your `dotenv` files.

### Step 1: Create Config File

Create `lib/config/env_config.dart`:

```dart
import 'package:environment_config/environment_config.dart';

@DotEnvGen(
  filename: 'dotenv',
  fieldRename: FieldRename.screamingSnake,
  includeIfNull: false,
)
abstract class Env {
  const Env();

  /// IPTV Playlist URL
  String get iptvPlaylistUrl;
}
```

### Step 2: Generate Configuration

Run the build_runner to generate the configuration:

```bash
# One-time generation
dart run environment_config:generate

# Or watch mode
dart run environment_config:generate --watch
```

This will generate a `lib/config/env_config.g.dart` file with:
- Type-safe access to environment variables
- Validation that required fields exist
- Auto-completion in your IDE

### Step 3: Use Generated Config

```dart
import 'package:iptv_app/config/env_config.g.dart';

// Access your environment variables type-safely
final playlistUrl = Env().iptvPlaylistUrl;
```

## 🔐 Security

### What's Ignored by Git

All files matching `dotenv*` are ignored:

```gitignore
dotenv*
```

This means:
- ✅ `dotenv` - Ignored (safe)
- ✅ `dotenv.dev` - Ignored (safe)
- ✅ `dotenv.prod` - Ignored (safe)
- ✅ `dotenv.backup` - Ignored (safe)

### Why Non-Hidden Files?

We use `dotenv` instead of `.dotenv` (non-hidden files) because:
- **Firebase Hosting Compatibility**: Hidden files (starting with `.`) are not uploaded to Firebase
- **Better Visibility**: Easier to see and manage environment files
- **Consistent Naming**: Works across all platforms without special handling

### Best Practices

1. **Never commit actual credentials** - All dotenv files are git-ignored
2. **Use different files for different environments** - Separate dev/staging/production
3. **Generate examples on-demand** - Use `environment_config:generate` instead of committing example files
4. **Keep credentials local** - Each developer creates their own `dotenv`

## 📝 Available Variables

### Current Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `IPTV_PLAYLIST_URL` | Your IPTV M3U playlist URL | `http://domain.com/get.php?username=XXX&password=YYY&type=m3u` |

### Adding New Variables

1. Add to your local `dotenv`:
```env
NEW_VARIABLE=actual_value
```

2. Access in code:
```dart
final value = dotenv.env['NEW_VARIABLE'] ?? 'fallback';
```

3. (Optional) Share with team by running:
```bash
dart run environment_config:generate
```
This generates an example file other developers can reference.

## 🛠️ Troubleshooting

### Error: "Unable to load asset dotenv"

**Solution**: Make sure `dotenv` file exists in the project root:
```bash
touch dotenv
# Then add your variables
```

### Error: "Variable not found"

**Solution**: Check that the variable is defined in your `dotenv` file and use a fallback:
```dart
final value = dotenv.env['MY_VAR'] ?? 'default';
```

### Environment not loading

**Solution**: Ensure `dotenv.load()` is called before `runApp()` in `main.dart`:
```dart
Future<void> main() async {
  await dotenv.load(fileName: "dotenv");
  runApp(MyApp());
}
```

## 📚 Further Reading

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)
- [environment_config Documentation](https://pub.dev/packages/environment_config)
- [12-Factor App Methodology](https://12factor.net/config)

## 🔄 Switching Between Environments

### Option 1: Manual (Current Implementation)

Edit `lib/main.dart` to load different files:

```dart
// For development
await dotenv.load(fileName: "dotenv.dev");

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
2. **Document each variable** - Add comments in `.dotenv.example`
3. **Validate on startup** - Check critical variables exist before running the app
4. **Never log credentials** - Be careful with debug logging
5. **Rotate credentials regularly** - Change passwords/tokens periodically
