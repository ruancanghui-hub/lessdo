import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../theme/lessdo_theme.dart';
import '../legal/legal_content.dart';
import '../widgets/lessdo_top_bar.dart';
import 'legal_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        LessDoTopBar(title: l10n.settings),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            children: [
              _GroupTitle(l10n.appearance),
              _ThemePicker(store: store),
              _SettingsLink(
                icon: CupertinoIcons.globe,
                title: l10n.language,
                subtitle: _languageName(l10n, store.settings.language),
                onTap: () => _showLanguagePicker(context, store),
              ),
              _SettingsToggle(
                icon: CupertinoIcons.textformat_size,
                title: l10n.largeText,
                subtitle: l10n.largeTextSubtitle,
                value: store.settings.largeText,
                onChanged: (value) => store.updateSettingsWith(
                  (current) => current.copyWith(largeText: value),
                ),
              ),
              _GroupTitle(l10n.privacy),
              _SettingsToggle(
                icon: CupertinoIcons.lock_shield,
                title: l10n.faceIdLock,
                subtitle: l10n.faceIdLockSubtitle,
                value: store.settings.faceId,
                onChanged: (value) async {
                  final changed = await store.updateFaceId(value);
                  if (!changed && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.biometricUnavailable)),
                    );
                  }
                },
              ),
              _SettingsLink(
                icon: CupertinoIcons.lock,
                title: l10n.privacyPermissions,
                subtitle: l10n.privacyPermissionsSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LegalPage(
                      title: l10n.privacyPolicy,
                      content: privacyPolicy,
                    ),
                  ),
                ),
              ),
              _SettingsLink(
                icon: CupertinoIcons.doc_text,
                title: l10n.termsOfUse,
                subtitle: l10n.termsOfUseSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LegalPage(title: l10n.termsOfUse, content: termsOfUse),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _languageName(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.simplifiedChinese => l10n.languageSimplifiedChinese,
    };
  }

  Future<void> _showLanguagePicker(BuildContext context, AppController store) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final language in AppLanguage.values)
                ListTile(
                  minTileHeight: 52,
                  title: Text(_languageName(l10n, language)),
                  trailing: store.settings.language == language
                      ? const Icon(CupertinoIcons.check_mark)
                      : null,
                  onTap: () async {
                    await store.updateSettingsWith(
                      (settings) => settings.copyWith(language: language),
                    );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (final entry in LessDoTheme.themes.entries)
            Expanded(
              child: InkWell(
                onTap: () => store.updateSettingsWith(
                  (current) => current.copyWith(themeId: entry.key),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: store.settings.themeId == entry.key
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value.background,
                          border: Border.all(
                            color: entry.value.accent,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.white, spreadRadius: -4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        switch (entry.key) {
                          'system' => l10n.themeSystem,
                          'snow' => l10n.themeSnow,
                          'mint' => l10n.themeMint,
                          'sky' => l10n.themeSky,
                          'blush' => l10n.themeBlush,
                          _ => entry.value.name,
                        },
                        style: const TextStyle(
                          color: Color(0xFF80838B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF747780),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          _SettingsIcon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8C8F97),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            _SettingsIcon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8C8F97),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: Color(0xFFB5B7BE),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF54667E).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 19, color: const Color(0xFF59687B)),
    );
  }
}
