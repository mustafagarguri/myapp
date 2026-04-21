import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/calls/presentation/call_state.dart';
import '../features/notifications/notification_service.dart';
import '../services/api_service.dart';
import '../services/location_sync_service.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  final Color primaryRed = const Color(0xFFE53935);
  final Color darkGrey = const Color(0xFF37474F);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final locationMessage =
          await LocationSyncService.captureAndSendCurrentLocation();
      await NotificationService.instance.syncFcmTokenWithBackend();
      if (!mounted) return;
      await context.read<CallState>().loadActiveCall();

      if (!mounted) return;
      final displayName = _extractUserName(data) ?? 'المستخدم';
      final snackMessage = locationMessage == null
          ? 'مرحباً $displayName'
          : 'مرحباً $displayName. $locationMessage';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage), backgroundColor: primaryRed),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
        Navigator.pushNamed(
          context,
          '/signup-verify',
          arguments: {'email': _emailController.text.trim()},
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدخول: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractUserName(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      final fullName = user['full_name'];
      if (fullName is String && fullName.trim().isNotEmpty) return fullName;

      final first = (user['first_name'] as String?)?.trim() ?? '';
      final last = (user['last_name'] as String?)?.trim() ?? '';
      final composed = '$first $last'.trim();
      if (composed.isNotEmpty) return composed;

      final name = user['name'];
      if (name is String && name.trim().isNotEmpty) return name;
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['user'];
      if (nested is Map<String, dynamic>) {
        final name = nested['name'];
        if (name is String && name.trim().isNotEmpty) return name;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  const AppLogo(size: 140),
                  const SizedBox(height: 20),
                  Text(
                    'وريد',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: darkGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'سجل دخولك للمتابعة',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: TextStyle(color: darkGrey),
                      prefixIcon: Icon(Icons.email_outlined, color: primaryRed),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: primaryRed, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'البريد الإلكتروني مطلوب';
                      }
                      if (!value.contains('@')) {
                        return 'صيغة البريد الإلكتروني غير صحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      labelStyle: TextStyle(color: darkGrey),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryRed),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: primaryRed, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'كلمة المرور مطلوبة';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/reset-password'),
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ليس لديك حساب؟ ',
                        style: TextStyle(color: darkGrey),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            color: primaryRed,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
