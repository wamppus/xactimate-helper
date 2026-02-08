# Photo Namer - Insurance Inspection App

AdjustiMate clone for naming inspection photos with dropdown menus.

## Features

- 📷 **Camera integration** - Take photos directly in app
- 📝 **Dropdown menus** - Elevation, Area, Room, Damage Type, Details
- ⌨️ **Custom input** - Type custom values when needed
- 💾 **Auto-naming** - Photos saved with descriptive filenames
- 🚀 **Fast** - Minimal UI, quick capture workflow

## Output Examples

```
Front elevation - Gutter - Hail Damage to.jpg
Rear elevation - Roof Overview - Test Square overview.jpg
Interior - Living Room - Water Damage to ceiling.jpg
Front elevation - overview.jpg
```

## Build

### Prerequisites
- Flutter SDK 3.0+
- Android SDK

### Steps

```bash
cd app/photo_namer
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Categories

| Category | Options |
|----------|---------|
| Elevation | Front, Right, Rear, Left, Interior, Custom |
| Area | 30+ options (Roof, Slopes, Gutter, Siding, etc.) |
| Room | Living Room, Kitchen, Bedrooms, Baths, etc. (optional) |
| Damage | Hail, Wind, Water, Mech, No Damage, etc. |
| Detail | 30yr Laminate, Shingle Condition, Address, etc. (optional) |

## File Structure

```
lib/
├── main.dart           # App entry point
├── models/
│   └── category.dart   # Category data models
├── screens/
│   └── home_screen.dart # Main UI with camera + dropdowns
└── data/
    └── categories_data.dart # Hardcoded category options
```

## Customize Categories

Edit `lib/data/categories_data.dart` to add/remove options.

## Permissions

- Camera (required)
- Storage (to save photos)

Photos saved to: `/storage/emulated/0/PhotoNamer/`
