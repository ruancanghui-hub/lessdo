import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../theme/lessdo_theme.dart';
import '../widgets/lessdo_top_bar.dart';
import 'legal_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LessDoTopBar(title: 'Settings'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            children: [
              _ProfileRow(store: store),
              const _GroupTitle('Appearance'),
              _ThemePicker(store: store),
              _SettingsToggle(
                icon: CupertinoIcons.textformat_size,
                title: 'Large text',
                subtitle: 'More comfortable list reading',
                value: store.settings.largeText,
                onChanged: (value) => store.updateSettings(
                  store.settings.copyWith(largeText: value),
                ),
              ),
              const _GroupTitle('Privacy'),
              _SettingsToggle(
                icon: CupertinoIcons.lock_shield,
                title: 'Face ID lock',
                subtitle: 'Protect your private lists',
                value: store.settings.faceId,
                onChanged: (value) async {
                  final changed = await store.updateFaceId(value);
                  if (!changed && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biometric authentication is unavailable or was canceled.',
                        ),
                      ),
                    );
                  }
                },
              ),
              _SettingsLink(
                icon: CupertinoIcons.lock,
                title: 'Privacy & permissions',
                subtitle: 'How LessDo handles your data',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalPage(
                      title: 'Privacy Policy',
                      content: privacyPolicy,
                    ),
                  ),
                ),
              ),
              _SettingsLink(
                icon: CupertinoIcons.doc_text,
                title: 'Terms of Use',
                subtitle: 'Standard terms and subscriptions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalPage(
                      title: 'Terms of Use',
                      content: termsOfUse,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.person_crop_circle_fill,
            color: Color(0xFF7C8798),
            size: 42,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LessDo User',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 3),
                Text(
                  'Free plan · local-first',
                  style: TextStyle(color: Color(0xFF898C94), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (final entry in LessDoTheme.themes.entries)
            Expanded(
              child: InkWell(
                onTap: () => store.updateSettings(
                  store.settings.copyWith(themeId: entry.key),
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
                        entry.value.name,
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
