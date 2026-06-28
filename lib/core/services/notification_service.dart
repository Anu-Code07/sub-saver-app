import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';

class NotificationService {
  NotificationService(this._notificationRepository);

  final NotificationRepository _notificationRepository;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  Future<void> registerToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _notificationRepository.saveFcmToken(userId, token);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'subsaver_channel',
          'SubSavr Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
