# PixelMap

## Environment Setup

Copy this file to `.env` and fill in your values:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Ralph Agent System

The Ralph Agent System is a collection of n8n workflows that automate:

1. **Tile Processing** (`n8n/workflows/tile_processor.json`)
   - Downloads OSM tiles
   - Applies Minecraft-style pixelation
   - Caches processed tiles

2. **Fog Manager** (`n8n/workflows/fog_manager.json`)
   - Listens for new location data
   - Calculates explored areas
   - Updates fog of war state

3. **Track Processor** (`n8n/workflows/track_processor.json`)
   - Processes batch GPS tracks
   - Optimizes database updates
   - Runs on schedule

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build

# Run tests
flutter test

# Run app
flutter run

# Build release
flutter build apk
flutter build ios
```

## Database Migrations

When updating the schema:

1. Edit `supabase/schema.sql`
2. Apply changes to Supabase instance
3. Document changes in `CHANGELOG.md`

## Troubleshooting

### Location not working on Android
- Ensure location permissions are granted
- Check `AndroidManifest.xml` for required permissions
- Enable location in device settings

### iOS build issues
- Run `pod install` in `ios/` directory
- Ensure Xcode is up to date
- Check signing certificates

### Supabase connection errors
- Verify environment variables are set
- Check network connectivity
- Ensure RLS policies are configured
