import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import '../widgets/lessdo_top_bar.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LessDoTopBar(
              title: title,
              leadingIcon: CupertinoIcons.chevron_left,
              onLeading: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  SelectableText(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
