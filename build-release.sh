#!/bin/bash

# Expiry Tracker - Release Build Script
# This script builds production-ready APKs

echo "========================================="
echo "Expiry Tracker - Release Build"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter not found!${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if keystore exists
if [ ! -f "android/key.properties" ]; then
    echo -e "${YELLOW}⚠️  Warning: key.properties not found!${NC}"
    echo "The APK will be signed with debug key."
    echo ""
    read -p "Do you want to generate a release keystore now? (yes/no): " GENERATE
    if [ "$GENERATE" == "yes" ]; then
        ./generate-keystore.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to generate keystore${NC}"
            exit 1
        fi
    fi
fi

echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "Choose build type:"
echo "1. Full APK (130 MB) - Works on all devices"
echo "2. Split APKs (40-45 MB each) - Smaller, device-specific"
echo "3. App Bundle (80 MB) - For Google Play Store"
echo "4. All of the above"
echo ""
read -p "Enter choice (1-4): " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "🔨 Building full release APK..."
        flutter build apk --release
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ Build successful!${NC}"
            echo ""
            echo "📱 APK location:"
            echo "   build/app/outputs/flutter-apk/app-release.apk"
            echo ""
            ls -lh build/app/outputs/flutter-apk/app-release.apk
        else
            echo -e "${RED}❌ Build failed!${NC}"
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "🔨 Building split APKs..."
        flutter build apk --release --split-per-abi
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ Build successful!${NC}"
            echo ""
            echo "📱 APK locations:"
            echo "   build/app/outputs/flutter-apk/"
            echo ""
            ls -lh build/app/outputs/flutter-apk/*.apk
        else
            echo -e "${RED}❌ Build failed!${NC}"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "🔨 Building app bundle..."
        flutter build appbundle --release
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ Build successful!${NC}"
            echo ""
            echo "📱 AAB location:"
            echo "   build/app/outputs/bundle/release/app-release.aab"
            echo ""
            ls -lh build/app/outputs/bundle/release/app-release.aab
        else
            echo -e "${RED}❌ Build failed!${NC}"
            exit 1
        fi
        ;;
    4)
        echo ""
        echo "🔨 Building all variants..."
        
        echo ""
        echo "1/3 Building full APK..."
        flutter build apk --release
        
        echo ""
        echo "2/3 Building split APKs..."
        flutter build apk --release --split-per-abi
        
        echo ""
        echo "3/3 Building app bundle..."
        flutter build appbundle --release
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ All builds successful!${NC}"
            echo ""
            echo "📱 Build outputs:"
            echo ""
            echo "Full APK:"
            ls -lh build/app/outputs/flutter-apk/app-release.apk
            echo ""
            echo "Split APKs:"
            ls -lh build/app/outputs/flutter-apk/app-*-release.apk
            echo ""
            echo "App Bundle:"
            ls -lh build/app/outputs/bundle/release/app-release.aab
        else
            echo -e "${RED}❌ Build failed!${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}❌ Invalid choice!${NC}"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "Next steps:"
echo "1. Test the APK on a device"
echo "2. Distribute to users or upload to Play Store"
echo "3. Keep your keystore file safe!"
echo "========================================="
echo ""
