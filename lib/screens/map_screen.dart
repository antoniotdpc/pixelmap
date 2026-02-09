import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/pixel_map.dart';
import '../widgets/mini_map.dart';
import '../providers/map_providers.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const Stack(
        children: [
          PixelMap(),
          _TopBar(),
          _BottomControls(),
        ],
      ),
      floatingActionButton: const _MapFab(),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PixelMap',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Minecraft',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _IconButton(
                  icon: Icons.bar_chart,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                _IconButton(
                  icon: Icons.settings,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends ConsumerWidget {
  const _BottomControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFog = ref.watch(showFogOverlayProvider);
    final showTrack = ref.watch(showTrackProvider);
    final isTracking = ref.watch(trackingEnabledProvider);

    return Positioned(
      bottom: 16,
      left: 16,
      right: 80,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToggleButton(
                icon: Icons.cloud,
                label: 'Fog',
                isActive: showFog,
                onPressed: () => ref.read(showFogOverlayProvider.notifier).state = !showFog,
              ),
              _ToggleButton(
                icon: Icons.route,
                label: 'Track',
                isActive: showTrack,
                onPressed: () => ref.read(showTrackProvider.notifier).state = !showTrack,
              ),
              _ToggleButton(
                icon: Icons.gps_fixed,
                label: 'GPS',
                isActive: isTracking,
                onPressed: () => ref.read(trackingEnabledProvider.notifier).state = !isTracking,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isActive
              ? Border.all(color: Colors.amber)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.amber : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.amber : Colors.grey,
                fontSize: 10,
                fontFamily: 'Minecraft',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Center on current position
      },
      backgroundColor: Colors.amber,
      child: const Icon(Icons.my_location, color: Colors.black),
    );
  }
}
