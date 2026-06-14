import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key, required this.onSubmit, this.grocery = false});

  final Future<void> Function(String) onSubmit;
  final bool grocery;

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _controller = TextEditingController();
  var _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await widget.onSubmit(value);
      if (!mounted) return;
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      _errorText = error is StateError
          ? error.message.toString()
          : 'Could not add task';
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 60),
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
                    key: const Key('quick-add-field'),
                    controller: _controller,
                    enabled: !_submitting,
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
                    key: const Key('quick-add-submit'),
                    onPressed: _submitting ? null : _submit,
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
          if (_errorText != null)
            Text(
              _errorText!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.error,
              ),
            )
          else
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
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Color(0xFF999CA4)),
            ),
        ],
      ),
    );
  }
}
