# PixelMap

A Minecraft-style pixelated map mobile app with fog of war exploration system. Cross-platform (iOS/Android) built with Flutter.

![PixelMap Banner](assets/banner.png)

## Features

- 🗺️ **Pixelated Map Tiles**: OpenStreetMap data rendered with Minecraft-style pixelation
- 🌫️ **Fog of War**: Only reveals areas where you've been (GPS track-based)
- 🔍 **Minecraft Zoom Levels**: 5 zoom levels (0-4) from street view to world view
- 🧭 **Compass Heading**: Real-time orientation with compass indicator
- ☁️ **Cloud Sync**: Supabase backend for storing explored areas
- 🤖 **Agent System**: n8n workflows for tile processing and fog management

## Tech Stack

- **Frontend**: Flutter + flutter_map
- **Backend**: Supabase (PostgreSQL + PostGIS)
- **Automation**: n8n workflows
- **Image Processing**: Sharp/Canvas for server-side pixelation

## Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK
- Android Studio / Xcode (for mobile emulators)
- Supabase account
- n8n instance (optional, for agent workflows)

### 1. Clone and Setup

```bash
git clone <repository-url>
cd pixelmap

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build
```

### 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the database schema:
   ```bash
   psql -h your-project.supabase.co -U postgres -d postgres -f supabase/schema.sql
   ```
3. Get your project URL and anon key from Settings > API
4. Set environment variables:
   ```bash
   export SUPABASE_URL=https://your-project.supabase.co
   export SUPABASE_ANON_KEY=your-anon-key
   ```

### 3. Run the App

```bash
# Android
flutter run

# iOS (macOS only)
flutter run -d ios

# Or specify a device
flutter devices
flutter run -d <device-id>
```

### 4. Configure n8n Workflows (Optional)

1. Install n8n: `npm install -g n8n`
2. Start n8n: `n8n start`
3. Import workflows from `n8n/workflows/`:
   - `tile_processor.json` - Processes OSM tiles with pixelation
   - `fog_manager.json` - Manages fog of war revelation
   - `track_processor.json` - Processes GPS tracks

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│    Supabase     │────▶│   PostgreSQL    │
│                 │     │                 │     │   + PostGIS     │
│  - Map UI       │     │  - Auth         │     │                 │
│  - GPS Tracking │     │  - Realtime     │     │  - Users        │
│  - Fog Overlay  │     │  - Storage      │     │  - Locations    │
└─────────────────┘     └─────────────────┘     │  - Explored     │
         │                                      │    Areas        │
         │                                      └─────────────────┘
         │                                               ▲
         │                                               │
         ▼                                               │
┌─────────────────┐                           ┌─────────────────┐
│   n8n Agents    │───────────────────────────│  Tile Cache     │
│                 │                           │  Processing     │
│  - Tile Proc.   │                           │                 │
│  - Fog Manager  │                           │  - Pixelation   │
│  - Track Proc.  │                           │  - CDN Storage  │
└─────────────────┘                           └─────────────────┘
```

## Project Structure

```
pixelmap/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── explored_area.dart
│   │   └── user.dart
│   ├── services/                 # Business logic
│   │   ├── location_service.dart
│   │   └── supabase_service.dart
│   ├── providers/                # Riverpod state management
│   │   └── map_providers.dart
│   ├── screens/                  # UI screens
│   │   ├── map_screen.dart
│   │   ├── settings_screen.dart
│   │   └── stats_screen.dart
│   ├── widgets/                  # Reusable widgets
│   │   ├── pixel_map.dart
│   │   ├── fog_overlay.dart
│   │   ├── compass_widget.dart
│   │   └── user_marker.dart
│   └── utils/                    # Utilities
│       └── tile_utils.dart
├── supabase/
│   └── schema.sql                # Database schema
├── n8n/workflows/                # Agent workflows
│   ├── tile_processor.json
│   ├── fog_manager.json
│   └── track_processor.json
└── pubspec.yaml
```

## Zoom Levels

| Level | Description | Flutter Map Zoom | Pixelation |
|-------|-------------|------------------|------------|
| 0     | Street view | 19               | None       |
| 1     | Close       | 16               | Light      |
| 2     | Medium      | 13               | Medium     |
| 3     | Far         | 10               | Heavy      |
| 4     | World view  | 6                | Very Heavy |

## API Endpoints

### Supabase Functions

- `process_track_segment(user_id, track_geojson)` - Process GPS track
- `is_location_explored(user_id, lat, lng)` - Check fog status
- `get_fog_polygons(user_id, bbox)` - Get explored areas

## Configuration

### Environment Variables

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Optional: n8n
N8N_WEBHOOK_URL=https://your-n8n-instance.com
```

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PixelMap needs your location to reveal the fog of war on the map.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>PixelMap tracks your location in the background to continuously reveal the fog.</string>
```

## Development

### Running Tests

```bash
flutter test
```

### Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- OpenStreetMap contributors
- Flutter Map package
- Supabase team
- Minecraft for the inspiration

---

Made with 💚 and pixels
