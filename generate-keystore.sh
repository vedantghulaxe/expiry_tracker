#!/bin/bash

# Expiry Tracker - Keystore Generation Script
# This script generates a release keystore for signing the APK

echo "========================================="
echo "Expiry Tracker - Keystore Generator"
echo "========================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found!"
    echo "Please install Java JDK to use keytool"
    exit 1
fi

# Keystore configuration
KEYSTORE_FILE="expiry-tracker-release.jks"
KEY_ALIAS="expiry-tracker"
VALIDITY_DAYS=10000

echo "This script will generate a keystore for signing your APK."
echo ""
echo "⚠️  IMPORTANT: Save the passwords securely!"
echo "   You'll need them for future app updates."
echo ""

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  Warning: Keystore file already exists!"
    read -p "Do you want to overwrite it? (yes/no): " OVERWRITE
    if [ "$OVERWRITE" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
    rm "$KEYSTORE_FILE"
fi

# Get user input
read -p "Enter keystore password: " -s STORE_PASSWORD
echo ""
read -p "Confirm keystore password: " -s STORE_PASSWORD_CONFIRM
echo ""

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
    echo "❌ Error: Passwords don't match!"
    exit 1
fi

read -p "Enter key password (press Enter to use same as keystore): " -s KEY_PASSWORD
echo ""

if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD="$STORE_PASSWORD"
fi

# Get certificate details
echo ""
echo "Certificate Details:"
read -p "Your name (e.g., John Doe): " CN
read -p "Organization Unit (e.g., Development): " OU
read -p "Organization (e.g., Expiry Tracker): " O
read -p "City (e.g., Mumbai): " L
read -p "State (e.g., Maharashtra): " ST
read -p "Country Code (e.g., IN): " C

# Generate keystore
echo ""
echo "Generating keystore..."

keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generated successfully!"
    echo ""
    echo "Keystore file: $KEYSTORE_FILE"
    echo "Key alias: $KEY_ALIAS"
    echo ""
    
    # Create key.properties file
    echo "Creating android/key.properties..."
    cat > android/key.properties <<EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=../$KEYSTORE_FILE
EOF
    
    echo "✅ key.properties created!"
    echo ""
    echo "⚠️  IMPORTANT SECURITY NOTES:"
    echo "1. Backup $KEYSTORE_FILE to a secure location"
    echo "2. Save your passwords in a password manager"
    echo "3. Never commit key.properties or .jks files to Git"
    echo "4. Keep these files secure - you can't update your app without them!"
    echo ""
    echo "Next steps:"
    echo "1. Run: flutter build apk --release"
    echo "2. Your signed APK will be in: build/app/outputs/flutter-apk/"
    echo ""
else
    echo "❌ Error: Failed to generate keystore"
    exit 1
fi
