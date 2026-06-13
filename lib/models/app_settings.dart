class AppSettings {
  const AppSettings({
    this.themeId = 'snow',
    this.largeText = false,
    this.continuousReminder = false,
    this.cloudSync = false,
    this.calendarSync = false,
    this.faceId = false,
  });

  final String themeId;
  final bool largeText;
  final bool continuousReminder;
  final bool cloudSync;
  final bool calendarSync;
  final bool faceId;

  AppSettings copyWith({
    String? themeId,
    bool? largeText,
    bool? continuousReminder,
    bool? cloudSync,
    bool? calendarSync,
    bool? faceId,
  }) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      largeText: largeText ?? this.largeText,
      continuousReminder: continuousReminder ?? this.continuousReminder,
      cloudSync: cloudSync ?? this.cloudSync,
      calendarSync: calendarSync ?? this.calendarSync,
      faceId: faceId ?? this.faceId,
    );
  }

  Map<String, Object?> toJson() => {
    'themeId': themeId,
    'largeText': largeText,
    'continuousReminder': continuousReminder,
    'cloudSync': cloudSync,
    'calendarSync': calendarSync,
    'faceId': faceId,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      themeId: (json['themeId'] as String?) ?? 'snow',
      largeText: (json['largeText'] as bool?) ?? false,
      continuousReminder: (json['continuousReminder'] as bool?) ?? false,
      cloudSync: (json['cloudSync'] as bool?) ?? false,
      calendarSync: (json['calendarSync'] as bool?) ?? false,
      faceId: (json['faceId'] as bool?) ?? false,
    );
  }
}
