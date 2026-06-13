import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/task_list.dart';
import '../controllers/app_controller.dart';

Future<void> showNewListSheet(
  BuildContext context, {
  required AppController store,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NewListSheet(store: store),
  );
}

class _NewListSheet extends StatefulWidget {
  const _NewListSheet({required this.store});

  final AppController store;

  @override
  State<_NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends State<_NewListSheet> {
  final _controller = TextEditingController();
  var _kind = ListKind.standard;
  var _color = 0xFF2E7BF6;

  static const colors = [
    0xFF2E7BF6,
    0xFF50B978,
    0xFFFF765C,
    0xFF9B51E0,
    0xFFF0A500,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        30 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D9DD),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Expanded(
                  child: Text(
                    'New list',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () async {
                          await widget.store.addList(
                            name: _controller.text.trim(),
                            colorValue: _color,
                            kind: _kind,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: const Text(
                    'Create',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'List name',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF777A82),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Weekend trip',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _KindButton(
                    label: 'Standard',
                    icon: CupertinoIcons.list_bullet,
                    selected: _kind == ListKind.standard,
                    onTap: () => setState(() => _kind = ListKind.standard),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KindButton(
                    label: 'Grocery',
                    icon: CupertinoIcons.cart,
                    selected: _kind == ListKind.grocery,
                    onTap: () => setState(() => _kind = ListKind.grocery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: TextStyle(color: Color(0xFF777A82), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final color in colors) ...[
                  InkWell(
                    onTap: () => setState(() => _color = color),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: _color == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: _color == color
                          ? const Icon(
                              CupertinoIcons.check_mark,
                              color: Colors.white,
                              size: 17,
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.06) : Colors.transparent,
          border: Border.all(
            color: selected ? accent : const Color(0xFFDFE1E5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? accent : null),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: selected ? accent : null)),
          ],
        ),
      ),
    );
  }
}
