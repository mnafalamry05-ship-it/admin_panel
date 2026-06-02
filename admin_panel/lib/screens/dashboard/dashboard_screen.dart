import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _tradingVolume = 0;
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
        SupabaseService.getTradingVolume(),
        SupabaseService.getTotalWalletBalance(),
        SupabaseService.getActiveUsersCount(),
        SupabaseService.getPendingRequestsCount(),
        SupabaseService.getLastTransactions(),
        SupabaseService.getBalanceSummary(),
      ]);

      if (!mounted) return;
      setState(() {
        _tradingVolume = results[0] as double;
        _totalBalance = results[1] as double;
        _activeUsers = results[2] as int;
        _pendingRequests = results[3] as int;
        _lastTransactions = results[4] as List<Map<String, dynamic>>;
        _balanceSummary = results[5] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasBalanceMismatch {
    if (_balanceSummary == null) return false;
    final received = (_balanceSummary!['total_received'] as num).toDouble();
    final distributed = (_balanceSummary!['total_distributed'] as num).toDouble();
    return received != distributed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1a237e),
                              Color(0xFF1565C0),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'لوحة التحكم',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded,
                                          color: Colors.white),
                                      onPressed: _loadData,
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Alert Banner
                        if (_hasBalanceMismatch)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.error, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'تحذير: عدم تطابق الأرصدة',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      Text(
                                        'الرصيد الموزع لا يساوي الرصيد المستلم',
                                        style: AppTextStyles.bodySecondary.copyWith(
                                            color: AppColors.error.withValues(alpha: 0.8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            StatCard(
                              title: 'حجم التداول (YER)',
                              value: '${_numberFormat.format(_tradingVolume)} ﷼',
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.accent,
                            ),
                            StatCard(
                              title: 'إجمالي رصيد المحافظ',
                              value: '${_numberFormat.format(_totalBalance)} ﷼',
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.success,
                            ),
                            StatCard(
                              title: 'المستخدمون النشطون',
                              value: _activeUsers.toString(),
                              icon: Icons.people_outline_rounded,
                              iconColor: AppColors.secondary,
                            ),
                            StatCard(
                              title: 'طلبات الانتظار',
                              value: _pendingRequests.toString(),
                              icon: Icons.hourglass_empty_rounded,
                              iconColor: AppColors.warning,
                              isAlert: _pendingRequests > 0,
                            ),
                          ],
                        ),

                        // Balance Summary
                        if (_balanceSummary != null) ...[
                          const SizedBox(height: 20),
                          const SectionTitle(title: 'ملخص الأرصدة'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _BalanceItem(
                                    label: 'الرصيد المستلم',
                                    value:
                                        '${_numberFormat.format(_balanceSummary!['total_received'])} ﷼',
                                    color: AppColors.success,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 50,
                                    color: AppColors.divider),
                                Expanded(
                                  child: _BalanceItem(
                                    label: 'الرصيد الموزع',
                                    value:
                                        '${_numberFormat.format(_balanceSummary!['total_distributed'])} ﷼',
                                    color: _hasBalanceMismatch
                                        ? AppColors.error
                                        : AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Last Transactions
                        const SizedBox(height: 20),
                        const SectionTitle(title: 'آخر 5 عمليات'),
                        const SizedBox(height: 12),
                        ..._lastTransactions.map((t) => _TransactionTile(t)),

                        if (_lastTransactions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'لا توجد عمليات حتى الآن',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.heading3.copyWith(color: color),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile(this.transaction);

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
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.accent, size: 20),
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
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.success,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
