import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _appIcon = '@mipmap/ic_launcher';

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings(_appIcon);

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );

    await _createChannels();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _createChannels() async {
    const channels = [
      AndroidNotificationChannel('salary_ch', 'Salary Reminders', importance: Importance.max),
      AndroidNotificationChannel('goal_ch', 'Goal Reminders', importance: Importance.max),
      AndroidNotificationChannel('urgent_ch', 'Urgent Alerts', importance: Importance.max),
    ];

    for (var channel in channels) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> testNotificationNow() async {
    await _notificationsPlugin.show(
      0,
      'Blue Cash Test ',
      'System check: Notifications are active and healthy.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'urgent_ch',
          'Urgent Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: _appIcon,
          fullScreenIntent: true,
        ),
      ),
    );
  }

  static Future<void> scheduleSalaryReminder(int day) async {
    await _notificationsPlugin.zonedSchedule(
      101,
      'Salary Time! 💰',
      'Your monthly salary should be in. Update your balance now!',
      _nextInstanceOfDay(day),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'salary_ch',
          'Salary Reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: _appIcon,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // --- التعديل الجديد هنا ---
  static Future<void> scheduleGoalReminder({
    required String goalName,
    required DateTime targetDate,
    required double totalAmount,
  }) async {
    final now = DateTime.now();
    final differenceInDays = targetDate.difference(now).inDays;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'goal_ch',
      'Goal Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: _appIcon,
    );

    // إذا كانت المدة شهر (30 يوم) أو أقل، التحويش يبقى يومي
    if (differenceInDays > 0 && differenceInDays <= 30) {
      double dailyAmount = totalAmount / differenceInDays;

      await _notificationsPlugin.periodicallyShow(
        goalName.hashCode,
        'Daily Saving: $goalName 🎯',
        'Time to save ${dailyAmount.toStringAsFixed(1)} EGP today!',
        RepeatInterval.daily,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("Daily notification scheduled for $goalName");
    }
    // إذا كانت أكثر من شهر، نلتزم بالنظام الشهري (في نفس يوم التاريخ المحدد)
    else {
      double monthlyAmount = totalAmount / (differenceInDays / 30).ceil();

      await _notificationsPlugin.zonedSchedule(
        goalName.hashCode,
        'Monthly Goal: $goalName 🎯',
        'Monthly reminder to save ${monthlyAmount.toStringAsFixed(1)} EGP.',
        _nextInstanceOfDay(targetDate.day),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
      print("Monthly notification scheduled for $goalName");
    }
  }

  static tz.TZDateTime _nextInstanceOfDay(int day) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    int scheduledDay = day;

    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    if (day > lastDayOfMonth.day) {
      scheduledDay = lastDayOfMonth.day;
    }

    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, scheduledDay, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 1, scheduledDay, 9, 0);
    }
    return scheduledDate;
  }

  static Future<void> checkAndResetMonthlyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (doc.exists) {
      int lastResetMonth = doc.data()?['lastResetMonth'] ?? 0;
      int currentMonth = DateTime.now().month;

      if (currentMonth != lastResetMonth) {
        double currentSalary = (doc.data()?['salary'] ?? 0).toDouble();
        var expensesSnapshot = await userRef.collection('fixed_expenses').get();
        double totalExpenses = 0;

        for (var exp in expensesSnapshot.docs) {
          totalExpenses += (exp.data()['amount'] ?? 0).toDouble();
        }

        double surplus = currentSalary - totalExpenses;
        if (surplus > 0) {
          await userRef.update({'allTimeSavings': FieldValue.increment(surplus)});
        }

        for (var exp in expensesSnapshot.docs) {
          await exp.reference.delete();
        }

        await userRef.update({
          'lastResetMonth': currentMonth,
          'salary': 0,
        });
      }
    }
  }
}