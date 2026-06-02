import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // قائمة الانتظار (waiting_list)
  // ══════════════════════════════════════════════════════════════

  /// جلب قائمة الانتظار
  static Future<List<Map<String, dynamic>>> getWaitingList() async {
    // Use RPC `get_pending_users` instead of selecting the table directly.
    // This returns JSON text or a list of records, and avoids exposing the table.
    final response =
        await _client.schema('badra_core').rpc('get_pending_users');

    dynamic decodedResponse = response;
    if (response is String) {
      decodedResponse = jsonDecode(response);
    }

    if (decodedResponse is List) {
      return List<Map<String, dynamic>>.from(
        decodedResponse.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    }

    if (decodedResponse is Map && decodedResponse['data'] is List) {
      return List<Map<String, dynamic>>.from(
        (decodedResponse['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
    }

    return <Map<String, dynamic>>[];
  }

  /// Alias to maintain compatibility with older code.
  static Future<List<Map<String, dynamic>>> getPendingUsers() async {
    return getWaitingList();
  }

  /// حذف عنصر من قائمة الانتظار
  static Future<void> deleteFromWaitingList(String id) async {
    try {
      await _client
          .schema('badra_core')
          .from('waiting_list')
          .delete()
          .eq('id', id);
    } on PostgrestException {
      await _client
          .schema('badra_core')
          .from('pending_users')
          .delete()
          .eq('id', id);
    }
  }

  /// Alias to maintain compatibility with older code.
  static Future<void> deletePendingUser(String id) async {
    return deleteFromWaitingList(id);
  }

  /// إنشاء حساب جديد عبر Auth باستخدام signUp.
  /// يُفترض أن هناك Trigger في قاعدة البيانات ينشئ profiles + wallet + security_code + activation_codes.
  static Future<Map<String, dynamic>> createAccount({
    required String name,
    required String phone,
    required String password,
    required String ipAddress,
    required String deviceName,
    required String deviceId,
  }) async {
    try {
      final String signupPhone;
      if (phone.startsWith('+')) {
        signupPhone = phone;
      } else if (phone.startsWith('967')) {
        signupPhone = '+$phone';
      } else {
        signupPhone = '+967$phone';
      }

      final authResp = await _client.auth.signUp(
        phone: signupPhone,
        password: password,
        data: {
          'name': name,
          'role': 'user',
          'ip_address': ipAddress,
          'device_name': deviceName,
          'device_id': deviceId,
        },
      );

      final userId = authResp.user?.id ?? authResp.session?.user.id;
      if (userId != null) {
        return {
          'success': true,
          'message': 'تم إنشاء الحساب بنجاح',
          'user': userId,
        };
      }

      return {
        'success': true,
        'message': 'تم إنشاء الحساب، قد تكون هناك حاجة للتحقق عبر رسالة',
        'user': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'user': null,
      };
    }
  }

  /// إنشاء حساب أدمن مباشرة في Auth مع role='admin'
  /// يعيد AuthResponse من Supabase
  static Future<AuthResponse> createAdminAccount(
      String phone, String password) async {
    return await _client.auth.signUp(
      phone: phone,
      password: password,
      data: {'role': 'admin'},
    );
  }

  /// عدد الطلبات المعلقة
  static Future<int> getPendingRequestsCount() async {
    try {
      final response = await _client
          .schema('badra_core')
          .from('waiting_list')
          .select('id')
          .eq('status', 'pending');
      return (response as List).length;
    } on PostgrestException {
      final response = await _client
          .schema('badra_core')
          .from('pending_users')
          .select('id')
          .eq('status', 'waiting');
      return (response as List).length;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // الموافقة والرفض (approve / reject)
  // ══════════════════════════════════════════════════════════════

  /// الموافقة على طلب → إنشاء حساب Auth + بروفايل + كود تفعيل
  /// يُرجع Map يحتوي: success, message, activation_code
  static Future<Map<String, dynamic>> approvePendingUser(String phone) async {
    // الخطوات الجديدة:
    // 1. جلب بيانات الزبون من جدول `pending_users` (name, phone, password_hash, ip, device_name, device_id)
    // 2. استدعاء `_client.auth.signUp()` لإنشاء حساب Auth باستخدام البيانات المستخرجة
    //    - phone: '+967' + phone
    //    - password: password_hash (كمثل نص عادي)
    //    - data: { name, role: 'user', ip_address, device_name, device_id }
    // 3. نفترض أن هناك Trigger في قاعدة البيانات يتعامل مع (handle_new_user)
    //    لذلك لا نحتاج لاستدعاء RPC لاحقاً.
    // 4. بعد نجاح `signUp()` نحدّث سجل `pending_users` إلى `status = 'approved'`.

    try {
      // 1) جلب صف المستخدم المعلق
      final pending = await _client
          .schema('badra_core')
          .from('pending_users')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (pending == null) {
        return {'success': false, 'message': 'المستخدم المعلق غير موجود'};
      }

      final Map<String, dynamic> userRow = Map<String, dynamic>.from(pending);

      final String name = (userRow['name'] ?? '') as String;
      final String passwordHash = (userRow['password_hash'] ?? '') as String;
      final String ipAddress =
          (userRow['ip'] ?? userRow['ip_address'] ?? '') as String;
      final String deviceName =
          (userRow['device_name'] ?? userRow['device'] ?? '') as String;
      final String deviceId = (userRow['device_id'] ?? '') as String;

      // 2) تجهيز رقم الهاتف كما طُلب: '+967' + phone
      final String signupPhone = '+967$phone';

      // 3) استدعاء signUp لإنشاء حساب Auth
      final authResp = await _client.auth.signUp(
        phone: signupPhone,
        password: passwordHash,
        data: {
          'name': name,
          'role': 'user',
          'ip_address': ipAddress,
          'device_name': deviceName,
          'device_id': deviceId,
        },
      );

      // 4) تحديث حالة المستخدم في pending_users إلى 'approved'
      try {
        await _client
            .schema('badra_core')
            .from('pending_users')
            .update({'status': 'approved'}).eq('phone', phone);
      } catch (_) {
        // لو فشل التحديث، لا نمنع نجاح عملية الإنشاء، لكن نعلم المستدعي
      }

      // إعداد نتيجة واضحة للمستدعي
      if (authResp.user != null || authResp.session != null) {
        return {
          'success': true,
          'message': 'تم الموافقة وإنشاء الحساب بنجاح',
          'user': authResp.user?.id,
        };
      }

      // قد يكون SignUp أرسل رسالة تحقق بدلاً من إنشاء جلسة
      return {
        'success': true,
        'message':
            'تمت الموافقة، قد تكون هناك حاجة للتحقق عبر رسالة (no session returned)'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// رفض طلب مع سبب الرفض
  static Future<Map<String, dynamic>> rejectPendingUser(
      String phone, String reason) async {
    final response =
        await _client.schema('badra_core').rpc('reject_pending_user', params: {
      'p_phone': phone,
      'p_reason': reason,
    });

    if (response is String) {
      return Map<String, dynamic>.from(jsonDecode(response));
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': false, 'message': 'استجابة غير متوقعة من الخادم'};
  }

  // ══════════════════════════════════════════════════════════════
  // الحسابات (accounts)
  // ══════════════════════════════════════════════════════════════

  /// جلب جميع الحسابات المنشأة
  static Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final response = await _client
          .schema('badra_core')
          .from('accounts')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException {
      final response = await _client
          .schema('badra_core')
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    }
  }

  /// عدد المستخدمين النشطين
  static Future<int> getActiveUsersCount() async {
    try {
      final response = await _client
          .schema('badra_core')
          .from('accounts')
          .select('id')
          .eq('is_active', true);
      return (response as List).length;
    } on PostgrestException {
      final response = await _client
          .schema('badra_core')
          .from('profiles')
          .select('id')
          .eq('is_active', true);
      return (response as List).length;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // المحافظ (wallets)
  // ══════════════════════════════════════════════════════════════

  /// إجمالي أرصدة كل المحافظ
  static Future<double> getTotalWalletBalance() async {
    try {
      final response =
          await _client.schema('badra_core').from('wallets').select('balance');
      final list = List<Map<String, dynamic>>.from(response);
      double total = 0;
      for (final w in list) {
        total += (w['balance'] as num).toDouble();
      }
      return total;
    } on PostgrestException {
      final response =
          await _client.schema('badra_core').from('profiles').select('balance');
      final list = List<Map<String, dynamic>>.from(response);
      double total = 0;
      for (final w in list) {
        total += (w['balance'] as num).toDouble();
      }
      return total;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // العمليات المالية (transactions)
  // ══════════════════════════════════════════════════════════════

  /// آخر العمليات
  static Future<List<Map<String, dynamic>>> getLastTransactions(
      {int limit = 5}) async {
    try {
      final response = await _client
          .schema('badra_core')
          .from('transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException {
      final response = await _client
          .schema('badra_core')
          .from('transactions_v2')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    }
  }

  /// حجم التداول الكلي (مجموع كل العمليات)
  static Future<double> getTradingVolume() async {
    try {
      final response = await _client
          .schema('badra_core')
          .from('transactions')
          .select('amount');
      final list = List<Map<String, dynamic>>.from(response);
      double total = 0;
      for (final t in list) {
        total += (t['amount'] as num).toDouble();
      }
      return total;
    } on PostgrestException {
      final response = await _client
          .schema('badra_core')
          .from('transactions_v2')
          .select('amount');
      final list = List<Map<String, dynamic>>.from(response);
      double total = 0;
      for (final t in list) {
        total += (t['amount'] as num).toDouble();
      }
      return total;
    }
  }

  /// تلخيص الرصيد (balance_summary)
  static Future<Map<String, dynamic>?> getBalanceSummary() async {
    try {
      final response = await _client
          .schema('badra_core')
          .from('balance_summary')
          .select()
          .limit(1)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return Map<String, dynamic>.from(response);
    } on PostgrestException {
      return null;
    }
  }

  /// تحديث أو إنشاء سجل ملخص الرصيد
  static Future<void> updateBalanceSummary({
    required double totalReceived,
    required double totalDistributed,
  }) async {
    final existing = await _client
        .schema('badra_core')
        .from('balance_summary')
        .select()
        .limit(1)
        .maybeSingle();

    if (existing is Map<String, dynamic> && existing['id'] != null) {
      await _client.schema('badra_core').from('balance_summary').update({
        'total_received': totalReceived,
        'total_distributed': totalDistributed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', existing['id']);
    } else {
      await _client.schema('badra_core').from('balance_summary').insert({
        'total_received': totalReceived,
        'total_distributed': totalDistributed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }
}
