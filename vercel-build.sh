#!/bin/bash
set -e

# Vercel's build image doesn't include the Flutter SDK, so fetch it first.
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:$(pwd)/flutter/bin"

flutter config --enable-web --no-analytics
flutter doctor -v

# SUPABASE_URL / SUPABASE_ANON_KEY come from Vercel's Environment Variables
# (Project Settings > Environment Variables) — never hardcode them here.
cat > app.env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

flutter pub get
flutter build web --release
