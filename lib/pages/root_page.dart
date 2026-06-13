import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task_list.dart';
import '../controllers/app_controller.dart';
import 'focus_page.dart';
import 'list_detail_page.dart';
import 'lists_page.dart';
import 'settings_page.dart';
import 'today_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.store});

  final AppController store;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastLink;
  var _index = 0;
  String? _focusTaskId;

  @override
  void initState() {
    super.initState();
    _listenForLinks();
  }

  Future<void> _listenForLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleLink(initialLink),
      );
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  Future<void> _handleLink(Uri uri) async {
    if (!mounted || uri.scheme != 'lessdo' || uri.toString() == _lastLink) {
      return;
    }
    _lastLink = uri.toString();

    final action = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final list = _findList(uri.queryParameters['list']);

    if (action == 'create') {
      final content = uri.queryParameters['content']?.trim();
      if (content == null || content.isEmpty) return;
      final reminder = _parseUrlDateTime(
        uri.queryParameters['date'],
        uri.queryParameters['time'],
      );
      await widget.store.addTask(
        text: content,
        listId: list?.id ?? 'inbox',
        dueAt: reminder,
        reminderAt: reminder,
      );
      if (mounted) _setIndex(0);
    } else if (action == 'open' && list != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ListDetailPage(store: widget.store, listId: list.id),
        ),
      );
    }

    final callback = uri.queryParameters['x-success'];
    if (callback != null) {
      final callbackUri = Uri.tryParse(callback);
      if (callbackUri != null && await canLaunchUrl(callbackUri)) {
        await launchUrl(callbackUri);
      }
    }
  }

  TaskList? _findList(String? name) {
    if (name == null) return null;
    for (final list in widget.store.lists) {
      if (list.name.toLowerCase() == name.toLowerCase()) return list;
    }
    return null;
  }

  DateTime? _parseUrlDateTime(String? date, String? time) {
    if (date == null) return null;
    final day = DateTime.tryParse(date);
    if (day == null) return null;
    final parts = time?.split(':');
    final hour = int.tryParse(parts?.firstOrNull ?? '') ?? 9;
    final minute =
        int.tryParse(parts != null && parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        height: 67,
        selectedIndex: _index,
        onDestinationSelected: _setIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.house),
            selectedIcon: Icon(CupertinoIcons.house_fill),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Lists',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.timer),
            selectedIcon: Icon(CupertinoIcons.timer_fill),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.gear),
            selectedIcon: Icon(CupertinoIcons.gear_solid),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
