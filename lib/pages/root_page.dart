import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task_list.dart';
import '../controllers/app_controller.dart';
import '../l10n/app_localizations.dart';
import '../navigation/deep_link_command.dart';
import 'focus_page.dart';
import 'list_detail_page.dart';
import 'lists_page.dart';
import 'settings_page.dart';
import 'task_editor_sheet.dart';
import 'today_page.dart';

class RootPage extends StatefulWidget {
  RootPage({
    super.key,
    required this.store,
    Future<Uri?> Function()? initialLink,
    Stream<Uri>? linkStream,
  }) : initialLink = initialLink ?? AppLinks().getInitialLink,
       linkStream = linkStream ?? AppLinks().uriLinkStream;

  final AppController store;
  final Future<Uri?> Function() initialLink;
  final Stream<Uri> linkStream;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<String>? _openTaskSubscription;
  String? _lastLink;
  var _index = 0;
  String? _focusTaskId;

  @override
  void initState() {
    super.initState();
    _listenForLinks();
    _openTaskSubscription = widget.store.openTaskRequests.listen(
      _handleOpenTaskRequest,
    );
  }

  Future<void> _listenForLinks() async {
    final initialLink = await widget.initialLink();
    if (initialLink != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleLink(initialLink),
      );
    }
    _linkSubscription = widget.linkStream.listen(_handleLink);
  }

  Future<void> _handleOpenTaskRequest(String taskId) async {
    if (!mounted || !widget.store.tasks.any((task) => task.id == taskId)) {
      return;
    }
    _setIndex(0);
    await showTaskEditor(context, store: widget.store, taskId: taskId);
  }

  Future<void> _handleLink(Uri uri) async {
    if (!mounted || uri.toString() == _lastLink) {
      return;
    }
    late final DeepLinkCommand command;
    try {
      command = DeepLinkCommand.parse(uri);
    } on FormatException {
      return;
    }
    _lastLink = uri.toString();

    switch (command) {
      case CreateTaskCommand():
        final list = _findList(command.listName);
        await widget.store.addTask(
          text: command.content,
          listId: list?.id ?? 'inbox',
          dueAt: command.scheduledAt,
          reminderAt: command.scheduledAt,
        );
        if (mounted) _setIndex(0);
      case OpenListCommand():
        final list = _findList(command.listName);
        if (list == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ListDetailPage(store: widget.store, listId: list.id),
          ),
        );
    }

    final callback = command.successCallback;
    if (callback != null && await canLaunchUrl(callback)) {
      await launchUrl(callback);
    }
  }

  TaskList? _findList(String? name) {
    if (name == null) return null;
    for (final list in widget.store.lists) {
      if (list.name.toLowerCase() == name.toLowerCase()) return list;
    }
    return null;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _openTaskSubscription?.cancel();
    super.dispose();
  }

  void _setIndex(int index) {
    setState(() {
      _index = index;
      if (index != 2) _focusTaskId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      TodayPage(
        store: widget.store,
        onOpenLists: () => _setIndex(1),
        onStartFocus: (taskId) {
          setState(() {
            _focusTaskId = taskId;
            _index = 2;
          });
        },
      ),
      ListsPage(store: widget.store),
      FocusPage(store: widget.store, initialTaskId: _focusTaskId),
      SettingsPage(store: widget.store),
    ];

    final destinations = [
      (
        icon: CupertinoIcons.house,
        selectedIcon: CupertinoIcons.house_fill,
        label: l10n.today,
      ),
      (
        icon: CupertinoIcons.list_bullet,
        selectedIcon: CupertinoIcons.list_bullet,
        label: l10n.lists,
      ),
      (
        icon: CupertinoIcons.timer,
        selectedIcon: CupertinoIcons.timer_fill,
        label: l10n.focus,
      ),
      (
        icon: CupertinoIcons.gear,
        selectedIcon: CupertinoIcons.gear_solid,
        label: l10n.settings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 800;
        final content = _PageViewport(
          child: IndexedStack(index: _index, children: pages),
        );
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: _setIndex,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final destination in destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  height: 67,
                  selectedIndex: _index,
                  onDestinationSelected: _setIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _PageViewport extends StatelessWidget {
  const _PageViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
