import 'package:flutter/material.dart';

import '../services/api_service.dart';

enum _ResetStep { requestOtp, verifyOtp, setPassword }

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  _ResetStep _step = _ResetStep.requestOtp;
  bool _isLoading = false;
  String? _resetToken;

  Future<void> _sendOtp({bool isResend = false}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('أدخل بريدًا إلكترونيًا صحيحًا.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.forgotPassword(email);
      if (!mounted) return;

      setState(() {
        _step = _ResetStep.verifyOtp;
      });

      final message =
          (response['message'] as String?) ??
          (isResend
              ? 'تمت إعادة إرسال رمز التحقق.'
              : 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.');
      _showSuccess(message);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('رمز التحقق يجب أن يكون 6 أرقام.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );
      if (!mounted) return;

      setState(() {
        _resetToken = response['reset_token'] as String?;
        _step = _ResetStep.setPassword;
      });

      _showSuccess(
        (response['message'] as String?) ??
            'تم التحقق من الرمز. يمكنك الآن تعيين كلمة مرور جديدة.',
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmation = _passwordConfirmationController.text.trim();

    if (_resetToken == null || _resetToken!.isEmpty) {
      _showError('رمز إعادة التعيين غير متوفر. أعد التحقق من OTP.');
      return;
    }
    if (password.length < 8) {
      _showError('كلمة المرور يجب أن تكون 8 أحرف على الأقل.');
      return;
    }
    if (password != confirmation) {
      _showError('كلمتا المرور غير متطابقتين.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.resetPassword(
        email: email,
        resetToken: _resetToken!,
        newPassword: password,
        passwordConfirmation: confirmation,
      );
      if (!mounted) return;

      _showSuccess(
        (response['message'] as String?) ??
            'تم تغيير كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول.',
      );
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Widget _buildRequestOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أدخل بريدك الإلكتروني لنرسل لك رمز استعادة كلمة المرور.',
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('إرسال رمز التحقق'),
        ),
      ],
    );
  }

  Widget _buildVerifyOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أدخل رمز التحقق المرسل إلى ${_emailController.text.trim()}.',
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'رمز التحقق',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('تأكيد الرمز'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
          child: const Text('إعادة إرسال الرمز'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _step = _ResetStep.requestOtp;
                    _otpController.clear();
                  });
                },
          child: const Text('تغيير البريد الإلكتروني'),
        ),
      ],
    );
  }

  Widget _buildSetPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أدخل كلمة المرور الجديدة ثم أكدها.',
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordConfirmationController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'تأكيد كلمة المرور',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('تغيير كلمة المرور'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_step) {
      case _ResetStep.requestOtp:
        content = _buildRequestOtpStep();
        break;
      case _ResetStep.verifyOtp:
        content = _buildVerifyOtpStep();
        break;
      case _ResetStep.setPassword:
        content = _buildSetPasswordStep();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.lock_reset, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }
}
