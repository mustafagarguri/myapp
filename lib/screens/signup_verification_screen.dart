import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/calls/presentation/call_state.dart';
import '../features/notifications/notification_service.dart';
import '../services/api_service.dart';
import '../services/location_sync_service.dart';

class SignUpVerificationScreen extends StatefulWidget {
  const SignUpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<SignUpVerificationScreen> createState() =>
      _SignUpVerificationScreenState();
}

class _SignUpVerificationScreenState extends State<SignUpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('رمز التحقق يجب أن يكون 6 أرقام.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.verifyRegistrationOtp(
        email: widget.email,
        otp: otp,
      );

      await NotificationService.instance.syncFcmTokenWithBackend();
      final locationMessage =
          await LocationSyncService.captureAndSendCurrentLocation();

      if (!mounted) return;
      await context.read<CallState>().loadActiveCall();
      if (!mounted) return;

      final message =
          (response['message'] as String?) ?? 'تم تأكيد الحساب بنجاح.';
      final snackMessage = locationMessage == null
          ? message
          : '$message $locationMessage';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage), backgroundColor: Colors.green),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.resendRegistrationOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (response['message'] as String?) ??
                'تمت إعادة إرسال رمز التحقق إلى بريدك الإلكتروني.',
          ),
          backgroundColor: Colors.green,
        ),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الحساب'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const Icon(
              Icons.mark_email_read_outlined,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'أرسلنا رمز تحقق إلى ${widget.email}. أدخله هنا لإكمال تفعيل الحساب.',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
                  : const Text('تأكيد الحساب'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: const Text('إعادة إرسال الرمز'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/signup',
                      (route) => false,
                    ),
              child: const Text('العودة إلى إنشاء الحساب'),
            ),
          ],
        ),
      ),
    );
  }
}
