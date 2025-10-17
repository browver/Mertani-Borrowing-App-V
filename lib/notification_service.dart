import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:user_app/firebase_services.dart';
import 'package:user_app/main.dart';
import 'package:user_app/menu_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';


class NotificationService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // INITIALIZE
  Future<void> initNotification(String username) async {
    if (_isInitialized) return;

    // prepare android init settings
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');

    // prepare ios init settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // init settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // init plugin
    // await notificationsPlugin.initialize(initSettings);
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final username = response.payload ?? await FirestoreServices.getCurrentUsername();
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => MyBorrowingsPage(userName: username, isSelf: true))
        );
      }
    );
    _isInitialized = true;

    _getUserBorrowedStats(username).listen((_) {});
  }

  

  // GET BORROWED ITEMS FROM USER
    Stream<Map<String, int>> _getUserBorrowedStats(String username) {
    return FirebaseFirestore.instance
        .collection('borrowed')
        .where('by', isEqualTo: username)
        .snapshots()
        .map((snapshot) {
      int totalBorrowed = 0;
      int activeBorrowed = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0) as int;
        final status = data['status'] ?? '';
        
        totalBorrowed += amount;
        if (status == 'dipinjam') {
          activeBorrowed += amount;
        }
      }

      _saveBorrowStats(username,totalBorrowed,activeBorrowed);
      
      return {
        'total': totalBorrowed,
        'active': activeBorrowed,
      };
    });
  }

  Future<void> _saveBorrowStats(String username, int total, int active) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalBorrowed_$username', total);
    await prefs.setInt('activeBorrowed_$username', active);

  }

  Future<Map<String, int>> getStatsFromPrefs(String username) async {
  final prefs = await SharedPreferences.getInstance();
  final total = prefs.getInt('totalBorrowed_$username') ?? 0;
  final active = prefs.getInt('activeBorrowed_$username') ?? 0;
  return {'total': total, 'active': active};
}


  // NOTIFICATION DETAIL SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id', 
        'daily_Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationsPlugin.show(id, title, body, notificationDetails());
  }

// SCHEDULER NOTIFICATION
Future<void> scheduleBorrowingNotifications({
  required String username,
  bool testing = false,
}) async {
  final now = tz.TZDateTime.now(tz.local);

  final scheduledDate = testing
      ? now.add(const Duration(seconds: 3))
      : now.add(const Duration(days: 7));

  const int idDeadline = 100;
  const int idReminder = 101;

  await notificationsPlugin.zonedSchedule(
    idDeadline,'Peringatan!!',
    'Hi $username kamu udah pinjam selama 7 hari, silahkan dikembalikan atau diperpanjang',
    scheduledDate,
    notificationDetails(),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: username,
  );

  // Updated items
  final snapshot = await FirebaseFirestore.instance
  .collection('borrowed')
  .where('by', isEqualTo: username)
  .get();

  int activeBorrowed = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final amount = (data['amount'] ?? 0) as int;
    final status = data['status'] ?? '';

    if (status == 'dipinjam') {
      activeBorrowed += amount;
    }
  }


  // Repeat notification
  await notificationsPlugin.zonedSchedule(
    idReminder,'Peringatan!!',
    'Hi $username jangan lupa segera kembalikan $activeBorrowed barang yang dipinjam!!',
    scheduledDate,
    notificationDetails(),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: username,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

// update Reminder notification
Future<void> updateReminderNotification(String username) async {
  final snapshot = await FirebaseFirestore.instance
  .collection('borrowed')
  .where('by', isEqualTo: username)
  .get();

  int activeBorrowed = 0;
  for (var doc in snapshot.docs) {
    final data = doc.data();
    final amount = (data['amount'] ?? 0) as int;
    final status = data['status'] ?? '';

    if (status == 'dipinjam') {
      activeBorrowed += amount;
    }
  }

  const int idReminder = 101;

  if(activeBorrowed > 0) {
    await notificationsPlugin.show(
      idReminder, 
      'Peringatan!!', 
      'Hi $username jangan lupa segera kembalikan $activeBorrowed barang yang dipinjam!!', 
      notificationDetails(),
      payload: username
    );
  } else {
    await cancelNotification(idReminder);
  }
}

// Stop all notifications
Future<void> cancelNotification(int id) async {
  await notificationsPlugin.cancel(id);
}

// Cancel all notificaitons
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

}