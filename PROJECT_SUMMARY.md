# PixelMap Project Summary

## Overview
A complete Flutter mobile application with Minecraft-style fog of war for map exploration.

## File Structure (48 files)

### Flutter App (`/lib`)
- `main.dart` - App entry point with Riverpod provider scope
- **Models** (`/models`):
  - `explored_area.dart` - Explored areas, user locations, tile coordinates with Freezed
  - `user.dart` - User, settings, and stats models with Freezed
  - `models.dart` - Export file
  
- **Services** (`/services`):
  - `location_service.dart` - GPS tracking, permission handling, location streaming
  - `supabase_service.dart` - Database operations, auth, RLS policies
  - `services.dart` - Export file
  
- **Providers** (`/providers`):
  - `map_providers.dart` - Riverpod providers for state management
  - `providers.dart` - Export file
  
- **Screens** (`/screens`):
  - `map_screen.dart` - Main map view with controls
  - `settings_screen.dart` - App settings UI
  - `stats_screen.dart` - Exploration statistics and achievements
  - `screens.dart` - Export file
  
- **Widgets** (`/widgets`):
  - `pixel_map.dart` - Main map widget with Flutter Map integration
  - `fog_overlay.dart` - Custom painter for fog of war effect
  - `compass_widget.dart` - Animated compass with heading display
  - `user_marker.dart` - User position marker with direction
  - `mini_map.dart` - Miniature overview map
  - `widgets.dart` - Export file
  
- **Utils** (`/utils`):
  - `tile_utils.dart` - Tile coordinate conversions, distance calculations
  - `utils.dart` - Export file

### Platform Configuration
- **Android** (`/android`):
  - `build.gradle` - App build configuration
  - `AndroidManifest.xml` - Permissions for location, internet
  - `MainApplication.java` - Application class
  
- **iOS** (`/ios`):
  - `Info.plist` - Location permissions, background modes
  - `Generated.xcconfig` - Flutter configuration

### Backend (`/supabase`)
- `schema.sql` - Complete database schema with:
  - Users, settings, stats tables
  - User locations with PostGIS geometry
  - Explored areas with spatial indexing
  - Tile cache table
  - RLS policies for security
  - Functions: process_track_segment, is_location_explored, get_fog_polygons

### Ralph Agent System (`/n8n/workflows`)
- `tile_processor.json` - Processes OSM tiles with Sharp pixelation
- `fog_manager.json` - Manages fog revelation based on GPS tracks
- `track_processor.json` - Batch processes uploaded track segments
- `daily_reports.json` - Generates daily exploration reports

### Worker Service (`/worker`)
- `index.js` - Node.js worker for tile processing with Sharp
- `package.json` - Dependencies (Sharp, Supabase client, Redis)

### Project Files
- `pubspec.yaml` - Flutter dependencies (flutter_map, geolocator, supabase_flutter, etc.)
- `analysis_options.yaml` - Dart lint rules
- `.gitignore` - Version control exclusions

### Documentation
- `README.md` - Complete setup and usage guide
- `DEVELOPMENT.md` - Development commands and troubleshooting
- `CHANGELOG.md` - Version history
- `LICENSE` - MIT license
- `.env.example` - Environment variable template

### Docker & Deployment
- `docker-compose.yml` - Full stack: Supabase, n8n, Redis, worker
- `Dockerfile.worker` - Tile processing worker container

### Tests
- `test/tile_utils_test.dart` - Unit tests for tile utilities
- `test/widget_test.dart` - Widget test placeholder

## Key Features Implemented

1. **Flutter Cross-Platform App**
   - iOS and Android support
   - Material Design 3 with custom Minecraft theme
   - Riverpod state management

2. **Pixelated Map Tiles**
   - OpenStreetMap integration via flutter_map
   - Dynamic pixelation based on zoom level (0-4)
   - Tile caching system

3. **Fog of War System**
   - GPS track-based revelation
   - Configurable reveal radius (default 50m)
   - PostGIS spatial queries for efficient lookups

4. **Minecraft Zoom Levels**
   - 0: Street view (19) - No pixelation
   - 1: Close (16) - Light pixelation  
   - 2: Medium (13) - Medium pixelation
   - 3: Far (10) - Heavy pixelation
   - 4: World view (6) - Very heavy pixelation

5. **User Position & Compass**
   - Real-time GPS tracking with geolocator
   - Compass heading with flutter_compass
   - Animated direction indicator

6. **Supabase Backend**
   - PostgreSQL + PostGIS for geospatial data
   - Row Level Security (RLS) policies
   - Realtime subscriptions support
   - User authentication

7. **Ralph Agent System (n8n)**
   - Automated tile pixelation processing
   - Fog of war management
   - Batch track processing
   - Scheduled report generation

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter 3.0+, Dart |
| Maps | flutter_map, OpenStreetMap |
| State Management | flutter_riverpod |
| Location | geolocator, flutter_compass |
| Backend | Supabase (PostgreSQL + PostGIS) |
| Automation | n8n |
| Image Processing | Sharp (Node.js) |
| Containerization | Docker, Docker Compose |

## Next Steps for Development

1. Run `flutter pub get` to install dependencies
2. Run `flutter pub run build_runner build` to generate Freezed code
3. Set up Supabase project and run schema.sql
4. Configure environment variables
5. Import n8n workflows
6. Run `flutter run` to start development

## Total Lines of Code

- Dart: ~3000 lines
- SQL: ~350 lines
- JavaScript: ~200 lines
- JSON/Markdown: ~1500 lines

**Total: ~5000+ lines across 48 files**
