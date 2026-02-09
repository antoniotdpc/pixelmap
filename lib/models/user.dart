import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? username,
    String? avatarUrl,
    required DateTime createdAt,
    DateTime? lastActiveAt,
    required UserSettings settings,
    required UserStats stats,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(true) bool fogOfWarEnabled,
    @Default(50.0) double fogRevealRadius,
    @Default(0) int defaultZoomLevel,
    @Default(true) bool trackLocation,
    @Default(true) bool syncToCloud,
    @Default('minecraft') String mapStyle,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int totalDistanceMeters,
    @Default(0) int exploredTiles,
    @Default(0) int uniqueLocations,
    @Default(0) int daysActive,
    DateTime? firstExploredAt,
    DateTime? lastExploredAt,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}
