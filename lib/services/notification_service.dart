import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/recurring_bill.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> schedule(RecurringBill bill) async {
    final now = tz.TZDateTime.now(tz.local);

    var dueDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      bill.dueDay,
      9,
    );

    if (!dueDate.isAfter(now)) {
      dueDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        bill.dueDay,
        9,
      );
    }

    final reminderDate = dueDate.subtract(
      Duration(days: bill.reminderDays),
    );

    await plugin.zonedSchedule(
      bill.id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      'Bill due soon',
      '${bill.name} - ₹${bill.amount.toStringAsFixed(0)}',
      reminderDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bills',
          'Recurring bills',
          channelDescription: 'Monthly bill reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteDate,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
