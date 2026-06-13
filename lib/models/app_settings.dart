enum AppLanguage { system, english, simplifiedChinese }

class AppSettings {
  const AppSettings({
    this.themeId = 'system',
    this.largeText = false,
    this.faceId = false,
    this.hasCompletedOnboarding = false,
    this.language = AppLanguage.system,
  });

  final String themeId;
  final bool largeText;
  final bool faceId;
  final bool hasCompletedOnboarding;
  final AppLanguage language;

  AppSettings copyWith({
    String? themeId,
    bool? largeText,
    bool? faceId,
    bool? hasCompletedOnboarding,
    AppLanguage? language,
  }) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      largeText: largeText ?? this.largeText,
      faceId: faceId ?? this.faceId,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      language: language ?? this.language,
    );
  }

  Map<String, Object?> toJson() => {
    'themeId': themeId,
    'largeText': largeText,
    'faceId': faceId,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'language': language.name,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      themeId: (json['themeId'] as String?) ?? 'system',
      largeText: (json['largeText'] as bool?) ?? false,
      faceId: (json['faceId'] as bool?) ?? false,
      hasCompletedOnboarding:
          (json['hasCompletedOnboarding'] as bool?) ?? false,
      language: AppLanguage.values.byName(
        (json['language'] as String?) ?? AppLanguage.system.name,
      ),
    );
  }
}
