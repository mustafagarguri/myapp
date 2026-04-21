import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../domain/qr_payload_parser.dart';
import 'call_state.dart';

class CallQrVerifyScreen extends StatefulWidget {
  const CallQrVerifyScreen({super.key, required this.callId});

  final int callId;

  @override
  State<CallQrVerifyScreen> createState() => _CallQrVerifyScreenState();
}

class _CallQrVerifyScreenState extends State<CallQrVerifyScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isVerifying = false;
  String? _lastToken;

  String _friendlyQrError(Object error) {
    final raw = error.toString().trim();
    final normalized = raw.toLowerCase();

    if (normalized.contains('route') && normalized.contains('not defined')) {
      return 'تم تسجيل الوصول، لكن حدث خلل داخلي في الإشعار. حاول تحديث الشاشة.';
    }

    if (normalized.contains('network') || normalized.contains('internet')) {
      return 'تعذر الاتصال بالخادم أثناء التحقق من الرمز.';
    }

    return raw.isEmpty ? 'فشل التحقق من الرمز.' : raw;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isVerifying) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue;
    final token = extractVerificationTokenFromQrRaw(raw);
    if (token == null || token.isEmpty) return;

    if (_lastToken == token) return;
    _lastToken = token;

    setState(() => _isVerifying = true);

    try {
      await context.read<CallState>().verifyArrivalByQr(widget.callId, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الوصول، بانتظار تأكيد المستشفى.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyQrError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل التحقق: $message')));
      _lastToken = null;
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح رمز الوصول')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isVerifying
                    ? 'جار التحقق من الرمز...'
                    : 'وجه الكاميرا إلى رمز QR للتحقق من الوصول.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_isVerifying)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
