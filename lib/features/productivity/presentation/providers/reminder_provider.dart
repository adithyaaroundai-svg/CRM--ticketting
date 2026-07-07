import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/reminder.dart';
import '../../../../core/services/local_notification_service.dart';

part 'reminder_provider.g.dart';

const _remindersKey = 'app_reminders_storage';

@riverpod
class Reminders extends _$Reminders {
  Timer? _timer;

  @override
  List<Reminder> build() {
    _loadReminders();
    _startTimer();
    
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return [];
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_remindersKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        state = jsonList.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
        
        final now = DateTime.now();
        for (final r in state) {
          if (!r.isCompleted && !r.isTriggered && r.remindAt.isAfter(now)) {
            LocalNotificationService.scheduleNotification(
              id: r.id.hashCode,
              title: 'Reminder: ${r.companyName}',
              body: r.notes.isNotEmpty ? r.notes : 'Time for your reminder!',
              scheduledDate: r.remindAt,
            );
          }
        }
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(reminders.map((e) => e.toJson()).toList());
    await prefs.setString(_remindersKey, jsonString);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    final now = DateTime.now();
    var hasChanges = false;
    final updatedList = state.map((reminder) {
      if (!reminder.isCompleted && !reminder.isTriggered && reminder.remindAt.isBefore(now)) {
        hasChanges = true;
        // Trigger notification via the LastTriggeredReminder provider
        ref.read(lastTriggeredReminderProvider.notifier).trigger(reminder);
        return reminder.copyWith(isTriggered: true);
      }
      return reminder;
    }).toList();

    if (hasChanges) {
      state = updatedList;
      _saveReminders(updatedList);
    }
  }

  void addReminder(Reminder reminder) {
    state = [...state, reminder];
    _saveReminders(state);
    LocalNotificationService.scheduleNotification(
      id: reminder.id.hashCode,
      title: 'Reminder: ${reminder.companyName}',
      body: reminder.notes.isNotEmpty ? reminder.notes : 'Time for your reminder!',
      scheduledDate: reminder.remindAt,
    );
  }

  void completeReminder(String id) {
    final updatedList = state.map((r) => r.id == id ? r.copyWith(isCompleted: true) : r).toList();
    state = updatedList;
    _saveReminders(state);
    LocalNotificationService.cancelNotification(id.hashCode);
  }

  void removeReminder(String id) {
    final updatedList = state.where((r) => r.id != id).toList();
    state = updatedList;
    _saveReminders(state);
    LocalNotificationService.cancelNotification(id.hashCode);
  }
}

@riverpod
class LastTriggeredReminder extends _$LastTriggeredReminder {
  @override
  List<Reminder> build() {
    return [];
  }

  void trigger(Reminder reminder) {
    // Add to the list if not already present
    if (!state.any((r) => r.id == reminder.id)) {
      state = [...state, reminder];
    }
  }

  void dismiss(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}
