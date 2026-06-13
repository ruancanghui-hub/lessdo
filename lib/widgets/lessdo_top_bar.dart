import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LessDoTopBar extends StatelessWidget {
  const LessDoTopBar({
    super.key,
    required this.title,
    this.onLeading,
    this.leadingIcon = CupertinoIcons.list_bullet,
    this.onAdd,
  });

  final String title;
  final VoidCallback? onLeading;
  final IconData leadingIcon;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: [
            _TopButton(icon: leadingIcon, onPressed: onLeading),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (onAdd != null)
              _TopButton(icon: CupertinoIcons.add, onPressed: onAdd)
            else
              const SizedBox(
                width: 42,
                height: 42,
                child: Icon(CupertinoIcons.ellipsis, size: 23),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 23),
      style: IconButton.styleFrom(
        fixedSize: const Size(42, 42),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
    );
  }
}
