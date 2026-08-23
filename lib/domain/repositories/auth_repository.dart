import '../models/app_user.dart';

class PhoneVerification {
  const PhoneVerification({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;
}

abstract class AuthRepository {
  Stream<String?> authStateChanges();

  Future<PhoneVerification> sendPhoneCode(String phoneNumber);

  Future<AppUser> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    required String name,
    required String language,
    String? phoneNumber,
  });

  Future<AppUser> signInWithDemoAccount({required String language});

  Future<void> signOut();
}
