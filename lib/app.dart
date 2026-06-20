import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ads/app_open_ad_manager.dart';
import 'ads/mobile_ads_support.dart';
import 'controllers/app_controller.dart';
import 'l10n/app_localizations.dart';
import 'models/app_settings.dart';
import 'pages/onboarding_page.dart';
import 'pages/root_page.dart';
import 'theme/lessdo_theme.dart';

typedef AppLoader = Future<AppController> Function();
typedef LifecycleReconciler = Future<void> Function(AppController store);
typedef StartupErrorRecorder = Future<void> Function(Object error);

class AppDependencies {
  AppDependencies({
    required AppLoader load,
    LifecycleReconciler? reconcileLifecycle,
    Future<void> Function()? exportDiagnostics,
    StartupErrorRecorder? recordStartupError,
  }) : initialStore = null,
       _load = load,
       _reconcileLifecycle = reconcileLifecycle ?? _defaultReconcile,
       exportDiagnostics = exportDiagnostics ?? _noOp,
       recordStartupError = recordStartupError ?? _ignoreError;

  AppDependencies.loaded(AppController store)
    : initialStore = store,
      _load = (() async => store),
      _reconcileLifecycle = _defaultReconcile,
      exportDiagnostics = _noOp,
      recordStartupError = _ignoreError;

  final AppController? initialStore;
  final AppLoader _load;
  final LifecycleReconciler _reconcileLifecycle;
  final Future<void> Function() exportDiagnostics;
  final StartupErrorRecorder recordStartupError;
  Future<void>? _activeReconciliation;

  Future<AppController> load() => _load();

  Future<void> reconcile(AppController store) {
    final active = _activeReconciliation;
    if (active != null) return active;
    final future = _reconcileLifecycle(store);
    _activeReconciliation = future;
    void clear() {
      if (identical(_activeReconciliation, future)) {
        _activeReconciliation = null;
      }
    }

    future.then<void>((_) => clear(), onError: (_, _) => clear());
    return future;
  }

  static Future<void> _defaultReconcile(AppController store) =>
      store.reconcileLifecycle();

  static Future<void> _noOp() async {}

  static Future<void> _ignoreError(Object _) async {}
}

class LessDoApp extends StatefulWidget {
  LessDoApp({super.key, AppDependencies? dependencies, AppController? store})
    : assert(
        dependencies != null || store != null,
        'Provide dependencies or a loaded store.',
      ),
      dependencies = dependencies ?? AppDependencies.loaded(store!);

  final AppDependencies dependencies;

  @override
  State<LessDoApp> createState() => _LessDoAppState();
}

class _LessDoAppState extends State<LessDoApp> {
  AppController? _store;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _store = widget.dependencies.initialStore;
    if (_store == null) unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) setState(() => _startupError = null);
    try {
      final store = await widget.dependencies.load();
      if (mounted) setState(() => _store = store);
    } catch (error) {
      try {
        await widget.dependencies.recordStartupError(error);
      } catch (_) {
        // Diagnostic persistence must never block the recovery interface.
      }
      if (mounted) setState(() => _startupError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store != null) {
      return _LoadedApplication(
        store: store,
        dependencies: widget.dependencies,
      );
    }
    return _BootstrapApplication(
      error: _startupError,
      onRetry: _load,
      onExportDiagnostics: widget.dependencies.exportDiagnostics,
    );
  }
}

class _BootstrapApplication extends StatelessWidget {
  const _BootstrapApplication({
    required this.error,
    required this.onRetry,
    required this.onExportDiagnostics,
  });

  final Object? error;
  final VoidCallback onRetry;
  final Future<void> Function() onExportDiagnostics;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: LessDoTheme.build('system', largeText: false),
      darkTheme: LessDoTheme.buildDark(largeText: false),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          if (error == null) {
            return Scaffold(
              key: const Key('app-loading'),
              body: Center(
                child: Semantics(
                  label: l10n.startupLoading,
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          }
          return Scaffold(
            key: const Key('startup-recovery'),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_problem_rounded, size: 52),
                        const SizedBox(height: 20),
                        Text(
                          l10n.startupFailureTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.startupFailureBody,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('retry-startup'),
                          onPressed: onRetry,
                          child: Text(l10n.retry),
                        ),
                        TextButton(
                          key: const Key('export-diagnostics'),
                          onPressed: () => unawaited(onExportDiagnostics()),
                          child: Text(l10n.exportDiagnostics),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadedApplication extends StatefulWidget {
  const _LoadedApplication({required this.store, required this.dependencies});

  final AppController store;
  final AppDependencies dependencies;

  @override
  State<_LoadedApplication> createState() => _LoadedApplicationState();
}

class _LoadedApplicationState extends State<_LoadedApplication>
    with WidgetsBindingObserver {
  var _locked = false;
  var _authenticating = false;
  var _pendingAppOpenAd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.store.settings.faceId) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAppOpenAd());
    }
  }

  void _maybeShowAppOpenAd() {
    if (!MobileAdsSupport.enabled) return;
    if (_locked || _authenticating) {
      _pendingAppOpenAd = true;
      return;
    }
    _pendingAppOpenAd = false;
    appOpenAdManager.showAdIfAvailable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && widget.store.settings.faceId) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_reconcileAndUnlock());
      if (!_locked && !_authenticating) {
        _maybeShowAppOpenAd();
      }
    }
  }

  Future<void> _reconcileAndUnlock() async {
    try {
      await widget.dependencies.reconcile(widget.store);
    } catch (_) {
      // Recovery work is best effort; authentication must remain available.
    }
    if (_locked) await _unlock();
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
      if (unlocked && _pendingAppOpenAd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowAppOpenAd();
        });
      }
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
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          locale: switch (widget.store.settings.language) {
            AppLanguage.system => null,
            AppLanguage.english => const Locale('en'),
            AppLanguage.simplifiedChinese => const Locale('zh'),
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: LessDoTheme.build(
            widget.store.settings.themeId,
            largeText: widget.store.settings.largeText,
          ),
          darkTheme: LessDoTheme.buildDark(
            largeText: widget.store.settings.largeText,
          ),
          themeMode: widget.store.settings.themeId == 'system'
              ? ThemeMode.system
              : ThemeMode.light,
          home: _locked
              ? _LockPage(authenticating: _authenticating, onUnlock: _unlock)
              : widget.store.settings.hasCompletedOnboarding
              ? RootPage(store: widget.store)
              : OnboardingPage(
                  onComplete: () => widget.store.updateSettingsWith(
                    (settings) =>
                        settings.copyWith(hasCompletedOnboarding: true),
                  ),
                ),
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
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n.lockedTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.lockedBody,
                  style: const TextStyle(color: Color(0xFF777A82)),
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
                  label: Text(
                    authenticating ? l10n.authenticating : l10n.unlock,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
