# Pre-commit Hooks Setup

This project uses pre-commit hooks to ensure code quality before commits.

## Option 1: Using pre-commit framework (Recommended)

### Installation

1. Install pre-commit:
```bash
pip install pre-commit
# or
brew install pre-commit  # macOS
```

2. Install the hooks:
```bash
pre-commit install
```

3. (Optional) Run on all files:
```bash
pre-commit run --all-files
```

### What it checks:

- ✅ Dart code formatting (`dart format`)
- ✅ Flutter analysis (`flutter analyze`)
- ✅ All tests pass (`flutter test`)
- ✅ pubspec.yaml validity
- ✅ Trailing whitespace
- ✅ End of file newlines
- ✅ YAML syntax
- ✅ Large files
- ✅ Merge conflicts
- ✅ Line endings

## Option 2: Manual Git Hook (Without pre-commit)

If you don't want to install pre-commit, you can use the manual hook:

```bash
# On Linux/macOS
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# On Windows (Git Bash)
cp hooks/pre-commit .git/hooks/pre-commit
```

## Bypassing Hooks

If you need to commit without running hooks (not recommended):

```bash
git commit --no-verify -m "your message"
```

## Manual Checks

You can run these checks manually anytime:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Get dependencies
flutter pub get
```

## CI/CD

The same checks should be configured in your CI/CD pipeline to ensure code quality on pull requests.
