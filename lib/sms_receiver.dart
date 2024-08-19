import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:telephony/telephony.dart';

class SmsReceiver {
  final Function(SmsMessage) onMessageReceived;
  final Telephony telephony = Telephony.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  SmsReceiver({required this.onMessageReceived}) {
    _initializeSmsReceiver();
    _initializeNotifications();
  }

  Future<void> _initializeSmsReceiver() async {
    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _handleIncomingSms(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _handleIncomingSms(SmsMessage message) {
    onMessageReceived(message);
    _showNotification(message);
  }

  Future<void> _showNotification(SmsMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sms_channel_id',
      'SMS Notifications',
      channelDescription: 'Notifications for incoming SMS messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New SMS from ${message.address}',
      message.body,
      platformChannelSpecifics,
    );
  }
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // Handle background messages if needed
  print("SMS received in background: ${message.body}");
}