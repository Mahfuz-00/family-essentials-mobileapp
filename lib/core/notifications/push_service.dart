import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/places/domain/entities/place.dart';
import '../config/app_config.dart';
import 'device_token_api.dart';
import 'local_notifications.dart';
import 'speech.dart';

/// Push delivery: registers this device and turns a received message into a local
/// notification on the member's chosen channel.
///
/// Two boundaries worth knowing:
///
///  * While the app is running, a foreground message is shown locally, because
///    the system does not display it for us.
///  * While the app is backgrounded or closed, **the system** displays the
///    notification using the channel (Android) or bundled sound (iOS) that the
///    server chose. This class does not post a second one.
///
/// Without Firebase options at build time, [start] does nothing: the app still
/// runs, and arrival notifications still appear while it is open.
class PushService {
  PushService({
    required DeviceTokenApi tokens,
    required LocalNotifications notifications,
    required Speech speech,
  }) : _tokens = tokens,
       _notifications = notifications,
       _speech = speech;

  final DeviceTokenApi _tokens;
  final LocalNotifications _notifications;
  final Speech _speech;

  bool _started = false;

  Future<void> start() async {
    if (_started || !AppConfig.hasFirebase) {
      return;
    }

    _started = true;

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseSenderId,
          projectId: AppConfig.firebaseProjectId,
        ),
      );
    } catch (error) {
      // No Firebase project configured for this build. Not fatal.
      debugPrint('Push disabled: $error');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    // firebase_messaging 17 deprecates `getToken`/`onTokenRefresh` in favour of
    // `register()` + `onRegistered`. The token produced is the same; this stays
    // on the older pair until push delivery is verified on a device, because the
    // replacement's automatic-registration timing has not been observed here.
    // ignore: deprecated_member_use
    await _register(await messaging.getToken());

    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen(_register);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final placeId = message.data['place_id'];

      if (placeId is String && placeId.isNotEmpty) {
        _notifications.onArrivalTapped?.call(placeId);
      }
    });
  }

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _tokens.register(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      );
    } catch (error) {
      debugPrint('Device token registration failed: $error');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final style = data['style'] as String? ?? 'sound';

    final arrival = LocationArrival(
      id: int.tryParse('${data['notification_id'] ?? ''}') ?? 0,
      placeId: int.tryParse('${data['place_id'] ?? ''}') ?? 0,
      kind: data['kind'] as String? ?? 'other',
      status: 'sent',
      placeName: message.notification?.title,
      title: message.notification?.title,
      body: message.notification?.body,
    );

    await _notifications.showArrival(arrival, style: style);

    // Speech is only possible here: iOS cannot speak from a push, and neither
    // platform can speak while the app is closed.
    if (style == 'voice' && (message.notification?.body ?? '').isNotEmpty) {
      await _speech.speak(message.notification!.body!);
    }
  }
}
