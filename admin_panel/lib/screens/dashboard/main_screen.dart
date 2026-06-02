import 'dart:async';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../accounts/accounts_screen.dart';
import '../balance/balance_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  Timer? _inactivityTimer;
  final Duration _inactivityTimeout = const Duration(minutes: 5);

  final List<Widget> _screens = const [
    DashboardScreen(),
    AccountsScreen(),
    BalanceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تسجيل الخروج',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        content: const Text('هل تريد تسجيل الخروج من لوحة التحكم؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء',
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('خروج',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, _handleInactivityLogout);
  }

  void _resetInactivityTimer(PointerEvent _) {
    if (!mounted) return;
    _startInactivityTimer();
  }

  Future<void> _handleInactivityLogout() async {
    // Force sign out without confirmation due to inactivity
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _resetInactivityTimer,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index == 3) {
                _logout();
              } else {
                setState(() => _selectedIndex = index);
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_add_outlined),
                activeIcon: Icon(Icons.person_add_rounded),
                label: 'الحسابات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'الرصيد',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout_rounded),
                activeIcon: Icon(Icons.logout_rounded),
                label: 'خروج',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
