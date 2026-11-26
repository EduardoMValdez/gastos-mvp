import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'budget_channel',
      'Presupuesto',
      channelDescription: 'Alertas y recordatorios de presupuesto',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showBudgetAlert(String category, double percent) {
    return _plugin.show(
      id: category.hashCode & 0x7fffffff,
      title: 'Alerta de presupuesto',
      body: 'Has usado el ${percent.toStringAsFixed(0)} % de tu presupuesto semanal en $category',
      notificationDetails: _details,
    );
  }

  static Future<void> scheduleWeeklyReminder() {
    return _plugin.periodicallyShow(
      id: 1,
      title: 'Revisa tus gastos',
      body: 'Dale un vistazo a tu presupuesto de esta semana',
      repeatInterval: RepeatInterval.weekly,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}