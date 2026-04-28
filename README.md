# 📱 Expiry Tracker App

> AI-powered product and medicine expiry management system built with Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.8.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Overview

Expiry Tracker App is a comprehensive mobile application that helps users track expiry dates of products and medicines using AI-powered OCR, barcode scanning, and intelligent data extraction. The app works offline-first and supports multiple platforms.

### ✨ Key Features

- 🤖 **AI-Powered OCR** - Automatic text extraction from product labels
- 📷 **Barcode Scanning** - Support for 10+ barcode formats
- 💊 **Medicine Tracking** - Track medicines with dosage and prescription info
- 🛒 **Product Management** - Track food and household products
- 🔐 **Biometric Security** - Fingerprint/Face ID authentication
- 📊 **Analytics Dashboard** - Statistics and insights
- 🔔 **Expiry Notifications** - Timely alerts for expiring items
- 📱 **Cross-Platform** - Android, iOS, Web, Windows, macOS, Linux
- 💾 **Offline Support** - Works without internet connection
- 🎨 **Dark Mode** - Eye-friendly dark theme

## 📸 Screenshots

[Add screenshots here]

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.8.0 or higher
- Dart SDK 3.8.0 or higher
- Android Studio / Xcode (for mobile development)
- VS Code (recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/expiry-tracker-app.git
   cd expiry-tracker-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📚 Documentation

Comprehensive documentation is available in the following files:

| Document | Description |
|----------|-------------|
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Complete project structure and architecture |
| [DIRECTORY_TREE.txt](DIRECTORY_TREE.txt) | Visual directory tree with file counts |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick commands and common tasks |
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | API endpoints and integration details |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture patterns and design decisions |
| [BIOMETRIC_AUTHENTICATION.md](BIOMETRIC_AUTHENTICATION.md) | Biometric authentication guide |
| [FILE_DOCUMENTATION.md](FILE_DOCUMENTATION.md) | Detailed file structure documentation |
| [FUNCTION_DOCUMENTATION.md](FUNCTION_DOCUMENTATION.md) | Function reference and usage |

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │  ← UI Screens & Widgets
├─────────────────────────────────────┤
│      Business Logic Layer           │  ← Services & BLoC
├─────────────────────────────────────┤
│      Data Layer                     │  ← Repositories & Database
├─────────────────────────────────────┤
│      External Services              │  ← APIs & ML Models
└─────────────────────────────────────┘
```

### Tech Stack

- **Framework:** Flutter 3.x
- **Language:** Dart 3.8.0+
- **State Management:** BLoC Pattern
- **Database:** Drift (SQLite ORM)
- **OCR:** Google ML Kit + Tesseract
- **Barcode:** Mobile Scanner
- **Authentication:** Local Auth (Biometric)

## 📦 Project Structure

```
lib/
├── main.dart                   # App entry point
├── core/                       # Core business logic
│   ├── services/              # 18 business services
│   └── utils/                 # Utility functions
├── data/                       # Data layer
│   ├── database/              # Database & tables
│   └── repositories/          # Data repositories
├── features/                   # Feature modules
│   ├── analytics/             # Analytics dashboard
│   ├── dashboard/             # Main dashboard
│   ├── product/               # Product tracking
│   ├── medicine/              # Medicine tracking
│   ├── inventory/             # Inventory management
│   └── settings/              # App settings
├── models/                     # Data models
└── services/                   # External services
```

**Total Files:** 62 Dart files
- Core Services: 18 files
- Feature Screens: 24 files
- Data Layer: 7 files
- External Services: 7 files

## 🔌 API Integrations

The app integrates with multiple external APIs:

| API | Purpose | Cost |
|-----|---------|------|
| **Oxlo.ai** | AI-powered OCR | Paid |
| **Open Food Facts** | Food product database | Free |
| **FDA Drug Database** | Medicine information | Free |
| **UPCItemDB** | General product lookup | Free trial |
| **Google ML Kit** | On-device OCR | Free |

## 🎨 Features in Detail

### 1. Product Entry Methods

- **Barcode Scanning** - Instant product lookup
- **Image Capture** - AI-powered data extraction
- **Manual Entry** - Form-based entry with validation

### 2. OCR Pipeline

```
Image → Validation → Online OCR → Offline OCR → Local Parser → Structured Data
```

Multi-stage pipeline with fallback mechanisms ensures high accuracy.

### 3. Data Management

- **Local SQLite Database** - Fast, offline-first storage
- **Drift ORM** - Type-safe database operations
- **Repository Pattern** - Clean data access layer

### 4. Security

- **Biometric Authentication** - Fingerprint/Face ID
- **Session Timeout** - Auto-lock after 5 minutes
- **Local Storage** - Data stays on device
- **Encrypted Preferences** - Secure configuration storage

## 🛠️ Development

### Common Commands

```bash
# Run app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Generate code
flutter pub run build_runner build

# Clean build
flutter clean
```

### Building for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/widget_test.dart
```

## 📊 Project Statistics

- **Total Lines of Code:** ~15,000
- **Dart Files:** 62
- **Supported Platforms:** 6 (Android, iOS, Web, Windows, macOS, Linux)
- **External APIs:** 5
- **Database Tables:** 3
- **Features:** 12 major features

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Write tests for new features
- Update documentation

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work*

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google ML Kit for OCR capabilities
- Open Food Facts for product database
- FDA for medicine information
- All open-source contributors

## 📞 Support

For support, email support@example.com or open an issue on GitHub.

## 🗺️ Roadmap

### Version 1.1 (Planned)
- [ ] Cloud sync (Firebase/Supabase)
- [ ] Multi-language support
- [ ] Barcode generation
- [ ] PDF reports
- [ ] Shopping list integration

### Version 1.2 (Future)
- [ ] Recipe suggestions
- [ ] Sharing functionality
- [ ] Widget support
- [ ] Advanced analytics
- [ ] Backup/restore

## 📈 Changelog

### Version 1.0.0+8 (Current)
- ✅ AI-powered OCR
- ✅ Barcode scanning
- ✅ Product and medicine tracking
- ✅ Biometric authentication
- ✅ Analytics dashboard
- ✅ Offline support
- ✅ Cross-platform support

## 🔗 Links

- [Documentation](PROJECT_STRUCTURE.md)
- [API Reference](API_DOCUMENTATION.md)
- [Architecture Guide](ARCHITECTURE.md)
- [Quick Reference](QUICK_REFERENCE.md)

---

**Made with ❤️ using Flutter**

**Version:** 1.0.0+8  
**Last Updated:** 2024
