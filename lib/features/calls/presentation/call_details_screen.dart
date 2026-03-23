import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../widgets/app_logo.dart';
import '../domain/call_details.dart';
import '../domain/call_status.dart';
import 'call_state.dart';
import 'widgets/waiting_status_card.dart';

class CallDetailsScreen extends StatefulWidget {
  const CallDetailsScreen({super.key, required this.callId});

  final int callId;

  @override
  State<CallDetailsScreen> createState() => _CallDetailsScreenState();
}

class _CallDetailsScreenState extends State<CallDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallState>().loadCallDetails(widget.callId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل النداء')),
      body: Consumer<CallState>(
        builder: (context, state, _) {
          if (state.loading && state.activeCall == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.activeCall == null) {
            return Center(child: Text(state.error!));
          }

          final call = state.activeCall;
          if (call == null) {
            return const Center(child: Text('لا يوجد نداء متاح حالياً'));
          }

          final isWaiting = call.myStatus == CallStatus.waitingList;
          final isCommitted = call.myStatus == CallStatus.accepted ||
              call.myStatus == CallStatus.checkedIn ||
              call.myStatus == CallStatus.arrived;
          final canGoTracking = isCommitted;
          final canAccept = call.uiType == CallUiType.acceptView && !isCommitted;
          final canWait = call.uiType == CallUiType.waitingListView && !isWaiting;
          final isCompleted = call.uiType == CallUiType.completedView;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const AppLogo(size: 70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(call.hospitalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('نداء عاجل', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('فصيلة الدم المطلوبة: ${call.bloodType}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('المسافة: ${call.distanceKm.toStringAsFixed(1)} كم'),
              const SizedBox(height: 8),
              Text('العدد المطلوب: ${call.requiredDonors} - الموافقون: ${call.acceptedCount}'),
              const SizedBox(height: 14),
              SizedBox(
                height: 190,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (call.hospitalLatitude == 0 && call.hospitalLongitude == 0)
                      ? Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Text('إحداثيات المستشفى غير متاحة حالياً'),
                        )
                      : GoogleMap(
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(call.hospitalLatitude, call.hospitalLongitude),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('hospital'),
                              position: LatLng(call.hospitalLatitude, call.hospitalLongitude),
                              infoWindow: InfoWindow(title: call.hospitalName),
                            ),
                          },
                        ),
                ),
              ),
              if (isWaiting) const WaitingStatusCard(),
              if (isCompleted)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text('تم إغلاق هذا النداء أو الاكتفاء بالعدد المطلوب.'),
                ),
              if (canGoTracking)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/call-tracking',
                      arguments: {'callId': call.id},
                    );
                  },
                  child: const Text('متابعة الالتزام'),
                ),
              const SizedBox(height: 16),
              if (canAccept)
                ElevatedButton(
                  onPressed: () async {
                    await state.respondAccepted(call.id);
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      '/call-tracking',
                      arguments: {'callId': call.id},
                    );
                  },
                  child: const Text('أنا قادم'),
                ),
              if (canAccept)
                TextButton(
                  onPressed: () async {
                    await state.respondRejected(call.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل الاعتذار')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('اعتذار'),
                ),
              if (canWait)
                OutlinedButton(
                  onPressed: () async {
                    await state.respondWaiting(call.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إدخالك إلى قائمة الانتظار')),
                    );
                  },
                  child: const Text('الاهتمام بالانتظار'),
                ),
            ],
          );
        },
      ),
    );
  }
}
