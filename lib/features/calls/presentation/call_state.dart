import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/api_service.dart';
import '../../realtime/realtime_service.dart';
import '../data/call_api_service.dart';
import '../domain/call_details.dart';
import '../domain/call_status.dart';
import '../domain/tracking_entry.dart';

class CallState extends ChangeNotifier {
  CallState(this._api, this._realtime);

  final CallApiService _api;
  final RealtimeService _realtime;

  bool loading = false;
  String? error;

  CallDetails? activeCall;
  List<TrackingEntry> tracking = const [];

  Duration remaining = const Duration(hours: 2);

  Timer? _countdownTimer;
  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  bool _expiring = false;

  Future<void> loadActiveCall() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      activeCall = await _api.getActiveCall();
      if (activeCall != null) {
        await _startRealtime(activeCall!.id);
        _startPolling(activeCall!.id);
      } else {
        await _stopLiveSync();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCallDetails(int callId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      activeCall = await _api.getCallDetails(callId);
      tracking = await _api.getCallTracking(callId);
      _applyCountdown(activeCall);
      await _startRealtime(callId);
      _startPolling(callId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> respondAccepted(int callId) async {
    await _api.respondToCall(callId, CallStatus.accepted);
    await loadCallDetails(callId);
  }

  Future<void> respondWaiting(int callId) async {
    await _api.respondToCall(callId, CallStatus.waitingList);
    await loadCallDetails(callId);
  }

  Future<void> respondRejected(int callId, {String? reason}) async {
    await _api.cancelCommitment(callId, reason: reason);
    activeCall = null;
    tracking = const [];
    await _stopLiveSync();
    notifyListeners();
  }

  Future<void> markExpiredIfNeeded(int callId) async {
    if (_expiring) return;
    _expiring = true;
    try {
      try {
        await _api.cancelCommitment(callId, reason: 'انتهاء المهلة');
      } catch (_) {
        await _api.clearActiveCallId();
      }
      activeCall = null;
      tracking = const [];
      await _stopLiveSync();
      notifyListeners();
    } finally {
      _expiring = false;
    }
  }

  Future<void> refreshTracking(int callId) async {
    try {
      tracking = await _api.getCallTracking(callId);
      notifyListeners();
    } catch (_) {
      // ignore transient errors
    }
  }

  void _applyCountdown(CallDetails? details) {
    _countdownTimer?.cancel();
    remaining = const Duration(hours: 2);

    final expiresAt = details?.commitmentExpiresAt;
    if (expiresAt == null) {
      notifyListeners();
      return;
    }

    void tick() {
      final diff = expiresAt.difference(DateTime.now());
      if (diff.isNegative) {
        remaining = Duration.zero;
        _countdownTimer?.cancel();
      } else {
        remaining = diff;
      }
      notifyListeners();
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _startPolling(int callId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        activeCall = await _api.getCallDetails(callId);
        tracking = await _api.getCallTracking(callId);
        _applyCountdown(activeCall);
        notifyListeners();
      } catch (_) {
        // Keep polling quietly.
      }
    });
  }

  Future<void> _startRealtime(int callId) async {
    await _realtime.connect(callId: callId, token: ApiService.token);
    await _eventSub?.cancel();

    _eventSub = _realtime.events.listen((event) async {
      final eventName = (event['event'] ?? event['type'] ?? '').toString();
      if (eventName.isEmpty) return;

      if (eventName == 'CallStatusUpdated' ||
          eventName == 'CallClosed' ||
          eventName == 'CallPromotedFromWaiting') {
        await loadCallDetails(callId);
      }
    });
  }

  Future<void> _stopLiveSync() async {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _eventSub?.cancel();
    _eventSub = null;
    await _realtime.disconnect();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _eventSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }
}
