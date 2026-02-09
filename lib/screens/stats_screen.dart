import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_providers.dart';
import '../models/user.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentTrack = ref.watch(currentTrackProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Exploration Stats',
          style: TextStyle(fontFamily: 'Minecraft'),
        ),
      ),
      body: currentUser.when(
        data: (user) => _StatsContent(user: user, trackLength: currentTrack.length),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _StatsContent(trackLength: currentTrack.length),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final User? user;
  final int trackLength;

  const _StatsContent({this.user, required this.trackLength});

  @override
  Widget build(BuildContext context) {
    final stats = user?.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.explore,
                  value: '${stats?.exploredTiles ?? 0}',
                  label: 'Tiles',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.location_on,
                  value: '${stats?.uniqueLocations ?? 0}',
                  label: 'Locations',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.timeline,
                  value: _formatDistance(stats?.totalDistanceMeters ?? 0),
                  label: 'Distance',
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Activity Section
          _SectionTitle('Activity'),
          const SizedBox(height: 8),
          _StatsCard(
            child: Column(
              children: [
                _ActivityRow(
                  icon: Icons.calendar_today,
                  label: 'Days Active',
                  value: '${stats?.daysActive ?? 0}',
                ),
                const Divider(color: Colors.grey),
                _ActivityRow(
                  icon: Icons.route,
                  label: 'Current Track Points',
                  value: '$trackLength',
                ),
                const Divider(color: Colors.grey),
                _ActivityRow(
                  icon: Icons.access_time,
                  label: 'First Explored',
                  value: _formatDate(stats?.firstExploredAt),
                ),
                const Divider(color: Colors.grey),
                _ActivityRow(
                  icon: Icons.update,
                  label: 'Last Active',
                  value: _formatDate(stats?.lastExploredAt ?? user?.lastActiveAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Achievements Section
          _SectionTitle('Achievements'),
          const SizedBox(height: 8),
          _StatsCard(
            child: Column(
              children: [
                _AchievementTile(
                  icon: Icons.emoji_flags,
                  title: 'First Steps',
                  description: 'Explore your first area',
                  isUnlocked: (stats?.exploredTiles ?? 0) > 0,
                ),
                const Divider(color: Colors.grey),
                _AchievementTile(
                  icon: Icons.hiking,
                  title: 'Wanderer',
                  description: 'Travel 1 km',
                  isUnlocked: (stats?.totalDistanceMeters ?? 0) >= 1000,
                ),
                const Divider(color: Colors.grey),
                _AchievementTile(
                  icon: Icons.map,
                  title: 'Cartographer',
                  description: 'Explore 100 tiles',
                  isUnlocked: (stats?.exploredTiles ?? 0) >= 100,
                  progress: (stats?.exploredTiles ?? 0) / 100,
                ),
                const Divider(color: Colors.grey),
                _AchievementTile(
                  icon: Icons.explore,
                  title: 'Explorer',
                  description: 'Visit 10 unique locations',
                  isUnlocked: (stats?.uniqueLocations ?? 0) >= 10,
                  progress: (stats?.uniqueLocations ?? 0) / 10,
                ),
                const Divider(color: Colors.grey),
                _AchievementTile(
                  icon: Icons.calendar_month,
                  title: 'Dedicated',
                  description: 'Active for 7 days',
                  isUnlocked: (stats?.daysActive ?? 0) >= 7,
                  progress: (stats?.daysActive ?? 0) / 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Minecraft',
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Minecraft',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Widget child;

  const _StatsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: child,
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Minecraft',
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final double? progress;

  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? Colors.amber : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                if (progress != null && !isUnlocked) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress!.clamp(0, 1),
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle, color: Colors.amber)
          else
            const Icon(Icons.lock, color: Colors.grey),
        ],
      ),
    );
  }
}
