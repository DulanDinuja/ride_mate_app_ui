import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';

import '../core/config/app_config.dart';
import 'token_service.dart';

/// Callback for received STOMP messages.
typedef StompMessageCallback = void Function(Map<String, dynamic> body);

/// Singleton wrapper around [StompClient] for the RideMate real-time layer.
///
/// Uses STOMP over SockJS to communicate with the Spring Boot backend.
///
/// Usage:
/// ```dart
/// await StompService.instance.activate();
/// final unsub = StompService.instance.subscribe(
///   '/topic/ride/42/location',
///   (body) => print('Driver moved to ${body['latitude']}, ${body['longitude']}'),
/// );
/// StompService.instance.send('/app/ride/42/location', {'latitude': 6.9, 'longitude': 79.8});
/// unsub(); // when done
/// StompService.instance.deactivate();
/// ```
class StompService {
  StompService._();
  static final StompService instance = StompService._();

  StompClient? _client;
  bool _isConnected = false;
  bool _isConnecting = false;

  /// Completer that resolves once the STOMP CONNECTED frame is received.
  Completer<void>? _connectCompleter;

  /// Pending subscriptions queued before the connection was ready.
  final List<_PendingSub> _pendingSubs = [];

  /// Active subscription handles (for cleanup).
  final Map<String, StompUnsubscribe> _activeSubs = {};

  // ─── Reconnect ───────────────────────────────────────────────────
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  Timer? _reconnectTimer;

  // ─── Public API ──────────────────────────────────────────────────

  bool get isConnected => _isConnected;

  /// Connect to the WebSocket server.
  ///
  /// Safe to call multiple times — only the first call opens the connection;
  /// subsequent calls wait for the same connection.
  Future<void> activate() async {
    if (_isConnected) return;
    if (_isConnecting) {
      await _connectCompleter?.future;
      return;
    }

    _isConnecting = true;
    _connectCompleter = Completer<void>();

    try {
      final token = await TokenService.getAccessToken();
      final url = AppConfig.sockJsUrl; // SockJS needs http(s) scheme

      dev.log('[StompService] Connecting to $url', name: 'StompService');

      _client = StompClient(
        config: StompConfig.sockJS(
          url: url,
          stompConnectHeaders: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          webSocketConnectHeaders: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onStompError,
          onWebSocketError: _onWebSocketError,
          // Heartbeat every 10s
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
          reconnectDelay: Duration.zero, // we handle reconnect ourselves
        ),
      );

      _client!.activate();
      await _connectCompleter!.future;
    } catch (e) {
      dev.log('[StompService] activate error: $e', name: 'StompService');
      _isConnecting = false;
      _connectCompleter?.completeError(e);
      _connectCompleter = null;
      _scheduleReconnect();
    }
  }

  /// Subscribe to a STOMP destination.
  ///
  /// Returns an **unsubscribe** callback.
  /// If the connection is not yet ready the subscription is queued.
  StompUnsubscribeHandle subscribe(
    String destination,
    StompMessageCallback onMessage,
  ) {
    final id = 'sub-${destination.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    void doSubscribe() {
      final unsub = _client!.subscribe(
        destination: destination,
        headers: {},
        callback: (frame) {
          if (frame.body == null) return;
          try {
            final body = jsonDecode(frame.body!) as Map<String, dynamic>;
            onMessage(body);
          } catch (e) {
            dev.log('[StompService] parse error on $destination: $e',
                name: 'StompService');
          }
        },
      );
      _activeSubs[id] = unsub;
    }

    if (_isConnected && _client != null) {
      doSubscribe();
    } else {
      _pendingSubs.add(_PendingSub(id, destination, onMessage, doSubscribe));
    }

    // Return a handle the caller can invoke to unsubscribe.
    return StompUnsubscribeHandle._(() {
      _activeSubs[id]?.call(unsubscribeHeaders: {});
      _activeSubs.remove(id);
      _pendingSubs.removeWhere((s) => s.id == id);
    });
  }

  /// Send a message to a STOMP destination (e.g. `/app/ride/{id}/location`).
  void send(String destination, Map<String, dynamic> body) {
    if (!_isConnected || _client == null) {
      dev.log('[StompService] send skipped — not connected',
          name: 'StompService');
      return;
    }
    _client!.send(
      destination: destination,
      body: jsonEncode(body),
    );
  }

  /// Gracefully disconnect.
  void deactivate() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    for (final unsub in _activeSubs.values) {
      try {
        unsub(unsubscribeHeaders: {});
      } catch (_) {}
    }
    _activeSubs.clear();
    _pendingSubs.clear();

    _client?.deactivate();
    _client = null;
    _isConnected = false;
    _isConnecting = false;
    _connectCompleter = null;
    dev.log('[StompService] Deactivated', name: 'StompService');
  }

  // ─── Callbacks ───────────────────────────────────────────────────

  void _onConnect(StompFrame frame) {
    dev.log('[StompService] Connected ✓', name: 'StompService');
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0;

    // Flush pending subscriptions
    for (final pending in _pendingSubs) {
      pending.subscribeFn();
    }
    _pendingSubs.clear();

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete();
    }
  }

  void _onDisconnect(StompFrame frame) {
    dev.log('[StompService] Disconnected', name: 'StompService');
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _onStompError(StompFrame frame) {
    dev.log('[StompService] STOMP error: ${frame.body}', name: 'StompService');
    _isConnected = false;
    _isConnecting = false;
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.completeError(
          Exception('STOMP error: ${frame.body}'));
    }
    _scheduleReconnect();
  }

  void _onWebSocketError(dynamic error) {
    dev.log('[StompService] WebSocket error: $error', name: 'StompService');
    _isConnected = false;
    _isConnecting = false;
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.completeError(error);
    }
    _scheduleReconnect();
  }

  // ─── Reconnect with exponential back-off ─────────────────────────

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      dev.log('[StompService] Max reconnect attempts reached',
          name: 'StompService');
      return;
    }
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 30));
    dev.log(
      '[StompService] Reconnecting in ${delay.inSeconds}s '
      '(attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)',
      name: 'StompService',
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connectCompleter = null;
      activate();
    });
  }
}

// ─── Helpers ─────────────────────────────────────────────────────

class _PendingSub {
  final String id;
  final String destination;
  final StompMessageCallback callback;
  final void Function() subscribeFn;

  _PendingSub(this.id, this.destination, this.callback, this.subscribeFn);
}

/// Handle returned by [StompService.subscribe] to unsubscribe later.
class StompUnsubscribeHandle {
  final void Function() _unsub;
  StompUnsubscribeHandle._(this._unsub);

  /// Unsubscribe from the STOMP destination.
  void unsubscribe() => _unsub();
}

