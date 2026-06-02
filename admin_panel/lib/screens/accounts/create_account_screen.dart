import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_theme.dart';

class CreateAccountScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final String? initialPassword;
  final String? initialIpAddress;
  final String? initialDeviceName;
  final String? initialDeviceId;

  const CreateAccountScreen({
    super.key,
    this.initialName,
    this.initialPhone,
    this.initialPassword,
    this.initialIpAddress,
    this.initialDeviceName,
    this.initialDeviceId,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ipController = TextEditingController();
  final _deviceController = TextEditingController();
  final _deviceIdController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _phoneController.text = widget.initialPhone ?? '';
    _passwordController.text = widget.initialPassword ?? '';
    _ipController.text = widget.initialIpAddress ?? '';
    _deviceController.text = widget.initialDeviceName ?? '';
    _deviceIdController.text = widget.initialDeviceId ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _deviceController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  bool get _isPrefilled {
    return (widget.initialName != null && widget.initialName!.isNotEmpty) ||
        (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) ||
        (widget.initialPassword != null &&
            widget.initialPassword!.isNotEmpty) ||
        (widget.initialIpAddress != null &&
            widget.initialIpAddress!.isNotEmpty) ||
        (widget.initialDeviceName != null &&
            widget.initialDeviceName!.isNotEmpty) ||
        (widget.initialDeviceId != null && widget.initialDeviceId!.isNotEmpty);
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await SupabaseService.createAccount(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        ipAddress: _ipController.text.trim(),
        deviceName: _deviceController.text.trim(),
        deviceId: _deviceIdController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء الحساب بنجاح',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final message = result['message']?.toString() ?? 'حدث خطأ غير معروف';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'إنشاء حساب جديد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a237e), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات الحساب الجديد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'أدخل جميع البيانات المطلوبة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person_outline_rounded,
                      enabled: !_isPrefilled,
                      validator: (v) => v!.isEmpty ? 'أدخل الاسم' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      enabled: !_isPrefilled,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'أدخل رقم الهاتف' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isPrefilled,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        labelStyle: AppTextStyles.bodySecondary,
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: _isPrefilled
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                        if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _ipController,
                      label: 'عنوان IP',
                      icon: Icons.router_outlined,
                      enabled: !_isPrefilled,
                      textAlign: TextAlign.left,
                      validator: (v) => v!.isEmpty ? 'أدخل عنوان IP' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _deviceController,
                      label: 'اسم الجهاز',
                      icon: Icons.phone_android_rounded,
                      enabled: !_isPrefilled,
                      validator: (v) => v!.isEmpty ? 'أدخل اسم الجهاز' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _deviceIdController,
                      label: 'معرّف الجهاز',
                      icon: Icons.fingerprint,
                      enabled: !_isPrefilled,
                      validator: (v) => v!.isEmpty ? 'أدخل معرّف الجهاز' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'إنشاء الحساب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'تمت المصادقة بالبصمة',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    TextAlign? textAlign,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textAlign: textAlign ?? TextAlign.start,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySecondary,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: validator,
    );
  }
}
