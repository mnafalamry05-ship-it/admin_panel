import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  bool _isLoading = true;
  double _totalBalance = 0;
  int _activeUsers = 0;
  int _pendingRequests = 0;
  List<Map<String, dynamic>> _lastTransactions = [];
  Map<String, dynamic>? _balanceSummary;

  final _numberFormat = NumberFormat('#,###', 'en');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getTotalWalletBalance(),
        SupabaseService.getActiveUsersCount(),
        SupabaseService.getPendingRequestsCount(),
        SupabaseService.getLastTransactions(),
        SupabaseService.getBalanceSummary(),
      ]);

      if (!mounted) return;
      setState(() {
        _totalBalance = results[0] as double;
        _activeUsers = results[1] as int;
        _pendingRequests = results[2] as int;
        _lastTransactions = results[3] as List<Map<String, dynamic>>;
        _balanceSummary = results[4] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBalance() async {
    final ok = await AuthService.authenticateWithBiometrics(
        'تحقق من هويتك لتحديث الرصيد');
    if (!ok || !mounted) return;

    _showUpdateDialog();
  }

  void _showUpdateDialog() {
    final receivedCtrl = TextEditingController(
        text: _balanceSummary?['total_received']?.toString() ?? '0');
    final distributedCtrl = TextEditingController(
        text: _balanceSummary?['total_distributed']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تحديث الرصيد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: receivedCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                labelText: 'الرصيد المستلم (YER)',
                labelStyle: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: distributedCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                labelText: 'الرصيد الموزع (YER)',
                labelStyle: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.updateBalanceSummary(
                  totalReceived: double.tryParse(receivedCtrl.text) ?? 0,
                  totalDistributed: double.tryParse(distributedCtrl.text) ?? 0,
                );
                _loadData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم تحديث الرصيد',
                        style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e',
                        style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تحديث',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الرصيد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Total Balance Hero Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1a237e), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1a237e).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded,
                                  color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'إجمالي رصيد المحافظ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Spacer(),
                              Text(
                                'YER',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_numberFormat.format(_totalBalance)} ﷼',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _StatPill(
                                  icon: Icons.people_outline_rounded,
                                  label: '$_activeUsers مستخدم نشط'),
                              const SizedBox(width: 10),
                              _StatPill(
                                  icon: Icons.hourglass_empty_rounded,
                                  label: '$_pendingRequests طلب انتظار'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Balance Summary
                    if (_balanceSummary != null) ...[
                      const SectionTitle(title: 'تفاصيل الأرصدة'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceDetailCard(
                              label: 'الرصيد المستلم',
                              value:
                                  '${_numberFormat.format(_balanceSummary!['total_received'])} ﷼',
                              icon: Icons.arrow_downward_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BalanceDetailCard(
                              label: 'الرصيد الموزع',
                              value:
                                  '${_numberFormat.format(_balanceSummary!['total_distributed'])} ﷼',
                              icon: Icons.arrow_upward_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Update Balance Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _updateBalance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.fingerprint, size: 22),
                        label: const Text(
                          'تحديث الرصيد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Last Transfers
                    const SectionTitle(title: 'آخر 5 تحويلات'),
                    const SizedBox(height: 12),
                    ..._lastTransactions.map((t) => _TransferTile(t)),

                    if (_lastTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'لا توجد تحويلات حتى الآن',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceDetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BalanceDetailCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style:
                  AppTextStyles.heading3.copyWith(color: color, fontSize: 15),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransferTile(this.transaction);

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,###', 'en');
    final amount = (transaction['amount'] as num).toDouble();
    final fromName = transaction['from_account']?['name'] ?? 'غير معروف';
    final toName = transaction['to_account']?['name'] ?? 'غير معروف';
    final date = DateTime.tryParse(transaction['created_at'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromName ← $toName',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (date != null)
                  Text(
                    DateFormat('yyyy/MM/dd - HH:mm', 'en').format(date),
                    style: AppTextStyles.label,
                  ),
              ],
            ),
          ),
          Text(
            '${format.format(amount)} ﷼',
            style: AppTextStyles.heading3
                .copyWith(color: AppColors.success, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
