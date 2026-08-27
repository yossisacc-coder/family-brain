import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required UserRepository users,
    FirebaseAuth? auth,
  })  : _users = users,
        _auth = auth ?? FirebaseAuth.instance;

  final UserRepository _users;
  final FirebaseAuth _auth;
  ConfirmationResult? _webConfirmation;

  @override
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<PhoneVerification> sendPhoneCode(String phoneNumber) async {
    final normalized = _normalizePhone(phoneNumber);
    if (kIsWeb) {
      _webConfirmation = await _auth.signInWithPhoneNumber(normalized);
      return PhoneVerification(
        verificationId: _webConfirmation!.verificationId,
      );
    }

    final completer = _PhoneCompleter();
    await _auth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: completer.fail,
      codeSent: (verificationId, resendToken) {
        completer.complete(
          PhoneVerification(
            verificationId: verificationId,
            resendToken: resendToken,
          ),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(PhoneVerification(verificationId: verificationId));
        }
      },
    );
    return completer.future;
  }

  @override
  Future<AppUser> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    required String name,
    required String language,
    String? phoneNumber,
  }) async {
    UserCredential credential;
    if (kIsWeb && _webConfirmation != null) {
      credential = await _webConfirmation!.confirm(smsCode);
    } else {
      credential = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      );
    }
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Phone verification did not produce a user.',
      );
    }
    return _upsertProfile(
      firebaseUser: user,
      name: name,
      language: language,
      phone: phoneNumber ?? user.phoneNumber ?? '',
    );
  }

  @override
  Future<AppUser> signInWithDemoAccount({required String language}) async {
    final verification = await sendPhoneCode(AppConfig.demoPhone);
    var code = AppConfig.demoOtp;
    if (AppConfig.useEmulator) {
      final emulatorCode = await _latestEmulatorSmsCode();
      if (emulatorCode != null) {
        code = emulatorCode;
      }
    }
    return verifyPhoneCode(
      verificationId: verification.verificationId,
      smsCode: code,
      name: AppConfig.demoName,
      language: language,
      phoneNumber: AppConfig.demoPhone,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _upsertProfile({
    required User firebaseUser,
    required String name,
    required String language,
    required String phone,
  }) async {
    final existing = await _users.getUser(firebaseUser.uid);
    if (existing != null) {
      final updated = existing.copyWith(
        name: name.isEmpty ? existing.name : name,
        language: language,
      );
      await _users.saveUser(updated);
      return updated;
    }
    final created = AppUser(
      id: firebaseUser.uid,
      name: name.isEmpty ? 'Family member' : name,
      phone: phone,
      language: language,
      createdAt: DateTime.now(),
    );
    await _users.saveUser(created);
    return created;
  }

  Future<String?> _latestEmulatorSmsCode() async {
    try {
      final host = kIsWeb
          ? AppConfig.emulatorHost
          : AppConfig.emulatorHost;
      final uri = Uri.parse(
        'http://$host:${AppConfig.authEmulatorPort}/emulator/v1/projects/family-brain-dev/verificationCodes',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final codes = data['verificationCodes'] as List? ?? const [];
      if (codes.isEmpty) return null;
      final last = codes.last as Map<String, dynamic>;
      return last['code'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _normalizePhone(String value) {
    final compact = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (compact.startsWith('+')) return compact;
    return '+$compact';
  }
}

class _PhoneCompleter {
  final Completer<PhoneVerification> _completer = Completer<PhoneVerification>();

  bool get isCompleted => _completer.isCompleted;

  void complete(PhoneVerification value) {
    if (_completer.isCompleted) return;
    _completer.complete(value);
  }

  void fail(Object error) {
    if (_completer.isCompleted) return;
    _completer.completeError(error);
  }

  Future<PhoneVerification> get future => _completer.future;
}
