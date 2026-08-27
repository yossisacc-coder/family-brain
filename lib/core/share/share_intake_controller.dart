import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'incoming_share.dart';

class ShareIntakeController extends StateNotifier<IncomingShare?> {
  ShareIntakeController({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('family_brain/share'),
        super(null);

  final MethodChannel _channel;
  var _bound = false;

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
    if (state?.id == share.id) return;
    state = share;
  }

  void clear() {
    state = null;
  }
}

final shareIntakeControllerProvider =
    StateNotifierProvider<ShareIntakeController, IncomingShare?>((ref) {
  return ShareIntakeController();
});
