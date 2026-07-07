// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Reminders)
const remindersProvider = RemindersProvider._();

final class RemindersProvider
    extends $NotifierProvider<Reminders, List<Reminder>> {
  const RemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remindersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remindersHash();

  @$internal
  @override
  Reminders create() => Reminders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Reminder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Reminder>>(value),
    );
  }
}

String _$remindersHash() => r'0e58a27863dbba39ccef25aff390543a39666e22';

abstract class _$Reminders extends $Notifier<List<Reminder>> {
  List<Reminder> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<Reminder>, List<Reminder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Reminder>, List<Reminder>>,
              List<Reminder>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(LastTriggeredReminder)
const lastTriggeredReminderProvider = LastTriggeredReminderProvider._();

final class LastTriggeredReminderProvider
    extends $NotifierProvider<LastTriggeredReminder, List<Reminder>> {
  const LastTriggeredReminderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastTriggeredReminderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastTriggeredReminderHash();

  @$internal
  @override
  LastTriggeredReminder create() => LastTriggeredReminder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Reminder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Reminder>>(value),
    );
  }
}

String _$lastTriggeredReminderHash() =>
    r'09f6dd6a044ed21ea1d1deec4dfacb6e1cca6402';

abstract class _$LastTriggeredReminder extends $Notifier<List<Reminder>> {
  List<Reminder> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<Reminder>, List<Reminder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Reminder>, List<Reminder>>,
              List<Reminder>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
