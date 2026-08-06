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

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await plugin.initialize(settings);

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

    if (dueDate.isBefore(now)) {
      dueDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        bill.dueDay,
        9,
      );
    }

    final notificationDate = dueDate.subtract(
      Duration(days: bill.reminderDays),
    );

    final notificationId =
        bill.id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await plugin.zonedSchedule(
      notificationId,
      'Bill due soon',
      '${bill.name} - ₹${bill.amount.toStringAsFixed(0)}',
      notificationDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bills',
          'Recurring bills',
          channelDescription: 'Monthly recurring bill reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
