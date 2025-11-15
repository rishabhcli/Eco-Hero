#!/bin/bash

echo "🔍 Verifying Firebase Configuration..."
echo ""

# Check if GoogleService-Info.plist exists
if [ -f "GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found in project root"
else
    echo "❌ GoogleService-Info.plist NOT found in project root"
    exit 1
fi

# Build the app
echo ""
echo "🔨 Building app..."
xcodebuild -project "Eco Hero.xcodeproj" -scheme "Eco Hero" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.1' build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded"
else
    echo "❌ Build failed"
    exit 1
fi

# Find the app bundle
APP_BUNDLE=$(find ~/Library/Developer/Xcode/DerivedData/Eco_Hero-*/Build/Products/Debug-iphonesimulator/ -name "Eco Hero.app" -type d | head -1)

if [ -z "$APP_BUNDLE" ]; then
    echo "❌ Could not find app bundle"
    exit 1
fi

echo "📦 App bundle: $APP_BUNDLE"
echo ""

# Check if GoogleService-Info.plist is in the bundle
if [ -f "$APP_BUNDLE/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist IS in app bundle"
    echo "✅ Firebase should work correctly now!"
    echo ""
    echo "🎉 All checks passed! You can run the app."
else
    echo "❌ GoogleService-Info.plist NOT in app bundle"
    echo ""
    echo "⚠️  ACTION REQUIRED:"
    echo "1. Open Xcode"
    echo "2. Select GoogleService-Info.plist in the Project Navigator"
    echo "3. In the right sidebar, under 'Target Membership', check 'Eco Hero'"
    echo "4. Clean build folder (Cmd+Shift+K)"
    echo "5. Rebuild (Cmd+B)"
    echo "6. Run this script again"
    exit 1
fi
