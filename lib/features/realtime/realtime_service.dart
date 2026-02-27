import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeService {
  WebSocketChannel? _channel;
  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect({
    required int callId,
    required String? token,
  }) async {
    await disconnect();

    final baseWs = const String.fromEnvironment(
      'CALL_SOCKET_URL',
      defaultValue: '',
    );
    if (baseWs.isEmpty) {
      return;
    }

    final uri = Uri.parse('$baseWs/private.call.$callId?token=${token ?? ''}');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (raw) {
        try {
          if (raw is String) {
            final payload = jsonDecode(raw);
            if (payload is Map<String, dynamic>) {
              _eventsController.add(payload);
            }
          }
        } catch (_) {
          // Ignore malformed events.
        }
      },
      onDone: () {
        _channel = null;
      },
      onError: (_) {
        _channel = null;
      },
    );
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
  }
}
