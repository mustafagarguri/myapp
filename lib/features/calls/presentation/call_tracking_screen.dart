import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/cancel_reason.dart';
import '../domain/call_status.dart';
import 'call_state.dart';

class CallTrackingScreen extends StatefulWidget {
  const CallTrackingScreen({super.key, required this.callId});

  final int callId;

  @override
  State<CallTrackingScreen> createState() => _CallTrackingScreenState();
}

class _CallTrackingScreenState extends State<CallTrackingScreen> {
  Timer? _expireWatcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallState>().loadCallDetails(widget.callId);
    });

    _expireWatcher = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final state = context.read<CallState>();
      if (state.remaining == Duration.zero && state.activeCall != null) {
        await state.markExpiredIfNeeded(state.activeCall!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتهت صلاحية الطلب، تم تحويل الحالة إلى منتهي.')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/home'));
      }
    });
  }

  @override
  void dispose() {
    _expireWatcher?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _cancelCommitment(BuildContext context, int callId) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('سبب الإلغاء (اختياري)')),
              for (final item in defaultCancelReasons)
                ListTile(
                  title: Text(item.label),
                  onTap: () => Navigator.pop(context, item.code),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('إلغاء بدون سبب'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;

    await context.read<CallState>().respondRejected(
          callId,
          reason: reason,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إلغاء المجيء بنجاح')),
    );
    Navigator.popUntil(context, ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الالتزام')),
      body: Consumer<CallState>(
        builder: (context, state, _) {
          final call = state.activeCall;
          if (state.loading && call == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (call == null) {
            return const Center(child: Text('لا يوجد التزام نشط الآن'));
          }

          final arrived = call.myStatus == CallStatus.arrived;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text('الوقت المتبقي للوصول', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(state.remaining),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('المستشفى: ${call.hospitalName}'),
              Text('المسافة التقديرية: ${call.distanceKm.toStringAsFixed(1)} كم'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openMaps(call.hospitalLatitude, call.hospitalLongitude),
                icon: const Icon(Icons.map_outlined),
                label: const Text('فتح الخرائط'),
              ),
              const SizedBox(height: 18),
              if (!arrived)
                TextButton(
                  onPressed: () => _cancelCommitment(context, call.id),
                  child: const Text('إلغاء المجيء'),
                ),
              const SizedBox(height: 18),
              const Text('حالة المتابعة', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final row in state.tracking)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.donorName),
                  subtitle: Text('الحالة: ${row.status.labelAr}'),
                  trailing: Text('${row.distanceKm.toStringAsFixed(1)} كم'),
                ),
            ],
          );
        },
      ),
    );
  }
}
