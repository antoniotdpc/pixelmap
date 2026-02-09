import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_providers.dart';
import '../models/user.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Minecraft'),
        ),
      ),
      body: currentUser.when(
        data: (user) => _SettingsList(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _SettingsList(),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  final User? user;

  const _SettingsList({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fogRadius = ref.watch(fogRevealRadiusProvider);
    final mapStyle = ref.watch(mapStyleProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Map Settings Section
        _SectionHeader(title: 'Map Settings'),
        _SettingsCard(
          children: [
            _SliderSetting(
              title: 'Fog Reveal Radius',
              subtitle: '${fogRadius.toInt()} meters',
              value: fogRadius,
              min: 10,
              max: 200,
              onChanged: (value) {
                ref.read(fogRevealRadiusProvider.notifier).state = value;
              },
            ),
            const Divider(color: Colors.grey),
            _DropdownSetting<String>(
              title: 'Map Style',
              value: mapStyle,
              items: const [
                DropdownMenuItem(value: 'minecraft', child: Text('Minecraft')),
                DropdownMenuItem(value: 'satellite', child: Text('Satellite')),
                DropdownMenuItem(value: 'terrain', child: Text('Terrain')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(mapStyleProvider.notifier).state = value;
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Tracking Settings Section
        _SectionHeader(title: 'Tracking'),
        _SettingsCard(
          children: [
            _SwitchSetting(
              title: 'Enable Location Tracking',
              subtitle: 'Record your movement to reveal fog',
              value: ref.watch(trackingEnabledProvider),
              onChanged: (value) {
                ref.read(trackingEnabledProvider.notifier).state = value;
              },
            ),
            const Divider(color: Colors.grey),
            _SwitchSetting(
              title: 'Sync to Cloud',
              subtitle: 'Backup explored areas to Supabase',
              value: user?.settings.syncToCloud ?? true,
              onChanged: (value) async {
                // Update user settings
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Account Section
        _SectionHeader(title: 'Account'),
        _SettingsCard(
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.white70),
              title: const Text(
                'Email',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                user?.email ?? 'Not signed in',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Sign out
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // About Section
        _SectionHeader(title: 'About'),
        _SettingsCard(
          children: [
            const ListTile(
              title: Text(
                'PixelMap',
                style: TextStyle(color: Colors.white, fontFamily: 'Minecraft'),
              ),
              subtitle: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              title: const Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.amber.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Minecraft',
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.amber,
            inactiveColor: Colors.grey.shade700,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      value: value,
      activeColor: Colors.amber,
      onChanged: onChanged,
    );
  }
}

class _DropdownSetting<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownSetting({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          DropdownButton<T>(
            value: value,
            dropdownColor: const Color(0xFF16213e),
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: Colors.amber),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
