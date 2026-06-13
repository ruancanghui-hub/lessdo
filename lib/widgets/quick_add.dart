import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key, required this.onSubmit, this.grocery = false});

  final ValueChanged<String> onSubmit;
  final bool grocery;

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              border: Border.all(color: accent, width: 1.5),
              borderRadius: BorderRadius.circular(27),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Icon(CupertinoIcons.add, size: 28, color: accent),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: widget.grocery
                          ? 'Add an item'
                          : 'What needs doing?',
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  TextButton(
                    onPressed: _submit,
                    child: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  SizedBox(
                    width: 42,
                    child: Icon(CupertinoIcons.mic, color: accent, size: 25),
                  ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              text: 'Smart input understands ',
              children: [
                TextSpan(
                  text: '“tomorrow at 2pm”',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: TextStyle(fontSize: 11, color: Color(0xFF999CA4)),
          ),
        ],
      ),
    );
  }
}
