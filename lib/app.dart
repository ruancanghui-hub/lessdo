import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'pages/root_page.dart';
import 'theme/lessdo_theme.dart';

class LessDoApp extends StatefulWidget {
  const LessDoApp({super.key, required this.store});

  final AppController store;

  @override
  State<LessDoApp> createState() => _LessDoAppState();
}

class _LessDoAppState extends State<LessDoApp> with WidgetsBindingObserver {
  var _locked = false;
  var _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.store.settings.faceId) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && widget.store.settings.faceId) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.reconcileReminders());
      if (_locked) _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    setState(() => _authenticating = true);
    final unlocked = await widget.store.authenticate();
    if (mounted) {
      setState(() {
        _locked = !unlocked;
        _authenticating = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return MaterialApp(
          title: 'LessDo',
          debugShowCheckedModeBanner: false,
          theme: LessDoTheme.build(
            widget.store.settings.themeId,
            largeText: widget.store.settings.largeText,
          ),
          home: _locked
              ? _LockPage(authenticating: _authenticating, onUnlock: _unlock)
              : RootPage(store: widget.store),
        );
      },
    );
  }
}

class _LockPage extends StatelessWidget {
  const _LockPage({required this.authenticating, required this.onUnlock});

  final bool authenticating;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                const Text(
                  'LessDo is locked',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Authenticate to view your lists.',
                  style: TextStyle(color: Color(0xFF777A82)),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: authenticating ? null : onUnlock,
                  icon: authenticating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint_rounded),
                  label: Text(authenticating ? 'Authenticating' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
