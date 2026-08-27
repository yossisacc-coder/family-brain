import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'incoming_share.dart';

class ShareIntakeController extends StateNotifier<IncomingShare?> {
  ShareIntakeController({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('family_brain/share'),
        super(null);

  final MethodChannel _channel;
  var _bound = false;
  final _seen = <String>{};

  Future<void> bind() async {
    if (_bound) return;
    _bound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShare' && call.arguments is Map) {
        apply(IncomingShare.fromMap(Map<dynamic, dynamic>.from(call.arguments as Map)));
      }
      return null;
    });
    try {
      final initial = await _channel.invokeMethod<Map<dynamic, dynamic>>('getInitial');
      if (initial != null) apply(IncomingShare.fromMap(initial));
    } catch (_) {}
  }

  void apply(IncomingShare share) {
    if (share.isEmpty) return;
    if (_seen.contains(share.id) || state?.id == share.id) return;
    state = share;
  }

  bool get hasProcessedPending => state != null;

  bool alreadyProcessed(String id) => _seen.contains(id);

  void clear() {
    final current = state;
    if (current != null) _seen.add(current.id);
    state = null;
  }
}

final shareIntakeControllerProvider =
    StateNotifierProvider<ShareIntakeController, IncomingShare?>((ref) {
  return ShareIntakeController();
});
