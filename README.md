# GLIMO - GPS Location Motorcycle

> Aplikasi pelacakan motor dengan GPS tracking otomatis dan monitoring servis berkala

## Features

- **GPS Tracking Otomatis**: Melacak perjalanan motor secara otomatis
- **Background Service**: Tracking berjalan di background bahkan saat aplikasi tertutup
- **Monitoring Servis**: Pengingat jadwal servis berkala berdasarkan kilometer
- **Riwayat Perjalanan**: Lihat history perjalanan dengan detail rute dan jarak
- **Multi Motor**: Kelola beberapa motor dalam satu akun
- **Activity Recognition**: Deteksi otomatis kapan sedang berkendara
- **Firebase Integration**: Sinkronisasi data real-time
- **Google Sign-In**: Login mudah dengan akun Google

## Tech Stack

- **Flutter** 3.35.0
- **Riverpod** - State management
- **Go Router** - Navigation
- **Firebase** (Auth, Firestore, Storage)
- **Google Maps** - Maps & Location
- **Background Service** - GPS tracking di background
- **Activity Recognition** - Deteksi aktivitas berkendara

## Getting Started

### Prerequisites
- Flutter SDK 3.35.0+
- FVM (recommended)
- Android Studio / Xcode
- Firebase account

### Quick Start

1. **Clone & Install**
   ```bash
   git clone <repository-url>
   cd GLIMO
   fvm flutter pub get
   ```

2. **Setup API Keys**
   ```bash
   # Copy example file
   cp android/local.properties.example android/local.properties

   # Edit dan tambahkan Google Maps API key
   # GOOGLE_MAPS_API_KEY=your_key_here
   ```

3. **Add Firebase Config**
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/google-services.json`

4. **Run**
   ```bash
   fvm flutter run
   ```

📖 **Detailed setup instructions**: See [SETUP.md](SETUP.md)

## Project Structure

```
lib/
├── application/        # UI Layer
│   ├── providers/     # Riverpod providers
│   ├── screens/       # App screens
│   ├── widgets/       # Reusable widgets
│   └── themes/        # Colors, typography, spacing
├── domain/            # Business logic
│   └── models/        # Data models
├── infrastructure/    # Data layer
│   └── services/      # External services
└── core/             # Core utilities
    └── utils/        # Helper utilities
```

## Testing

```bash
# Run all tests
fvm flutter test

# Run with coverage
fvm flutter test --coverage

# Run analyze
fvm flutter analyze
```

Current test status: ✅ 13 tests passing

## Building for Production

### Android
```bash
# APK
fvm flutter build apk --release

# App Bundle (for Play Store)
fvm flutter build appbundle --release
```

### iOS
```bash
fvm flutter build ios --release
```

⚠️ **Note**: Configure signing first! See [SETUP.md](SETUP.md#production-build)

## Security

This project uses secure environment configuration:
- API keys stored in `.env` and `local.properties` (git-ignored)
- Firebase config excluded from git
- Release signing keys excluded from git

**Never commit**:
- `.env`
- `android/local.properties`
- `android/key.properties`
- `google-services.json`
- `*.jks` keystore files

## Development

### Code Style
- Follow [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `fvm flutter analyze` to check for issues
- Run tests before committing

### Logging
Use the custom `Logger` utility instead of `debugPrint`:

```dart
import 'package:glimo/core/utils/logger.dart';

Logger.info('User logged in', tag: 'AUTH');
Logger.error('Failed to load', tag: 'API', error: e);
Logger.warn('Cache miss', tag: 'CACHE');
```

Logger automatically disables in production builds.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and analyze
4. Submit a pull request

## License

Personal Development Version

## Support

For issues and questions, please contact the development team.

---

Built with ❤️ using Flutter
