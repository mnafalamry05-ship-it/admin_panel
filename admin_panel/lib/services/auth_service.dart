import 'package:local_auth_android/local_auth_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static final _localAuth = LocalAuthentication();

  static Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// تسجيل الدخول باستخدام رقم الهاتف وكلمة المرور
  /// يعيد AuthResponse كما في signIn
  static Future<AuthResponse> signInWithPhone(
      String phone, String password) async {
    // استخدم حقل `phone` مباشرة لأن مزود البريد معطّل ومزود الهاتف مفعل
    return await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  static Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) return true; // skip if not supported

      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) return true;

      return await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'OAuth Authentication',
          ),
        ],
      );
    } catch (e) {
      return true; // allow if biometrics unavailable
    }
  }

  static User? get currentUser => _supabase.auth.currentUser;
}
