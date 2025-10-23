#!/bin/bash
# Run Flutter app in Chrome with CORS disabled (for development only)
flutter run -d chrome --web-browser-flag="--disable-web-security"
