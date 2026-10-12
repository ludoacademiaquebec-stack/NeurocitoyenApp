#!/bin/bash
set -e
echo "Installing Flutter..."
if [ ! -d "/tmp/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
fi
export PATH="/tmp/flutter/bin:$PATH"
flutter --version
flutter config --no-analytics
flutter pub get
flutter build web --release --base-href="/"
