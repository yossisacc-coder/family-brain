import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_trash.dart';

/// One Undo banner for every screen. Auto-dismiss is owned by [TaskTrash].
class UndoHost extends ConsumerWidget {
  const UndoHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(trashUndoRequestProvider) != null;
    return Stack(
      children: [
        child,
        if (pending)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 72),
                child: Material(
                  color: Colors.transparent,
                  child: TrashUndoBar(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
