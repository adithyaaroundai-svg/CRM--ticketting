// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatStream)
const chatStreamProvider = ChatStreamFamily._();

final class ChatStreamProvider
    extends $AsyncNotifierProvider<ChatStream, List<ChatMessage>> {
  const ChatStreamProvider._({
    required ChatStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatStreamProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatStreamHash();

  @override
  String toString() {
    return r'chatStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatStream create() => ChatStream();

  @override
  bool operator ==(Object other) {
    return other is ChatStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatStreamHash() => r'bd6e2bea4370111bc82115ad27ae340c2e5e78c0';

final class ChatStreamFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatStream,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          FutureOr<List<ChatMessage>>,
          String
        > {
  const ChatStreamFamily._()
    : super(
        retry: null,
        name: r'chatStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ChatStreamProvider call(String channel) =>
      ChatStreamProvider._(argument: channel, from: this);

  @override
  String toString() => r'chatStreamProvider';
}

abstract class _$ChatStream extends $AsyncNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get channel => _$args;

  FutureOr<List<ChatMessage>> build(String channel);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(DmStream)
const dmStreamProvider = DmStreamFamily._();

final class DmStreamProvider
    extends $AsyncNotifierProvider<DmStream, List<ChatMessage>> {
  const DmStreamProvider._({
    required DmStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dmStreamProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dmStreamHash();

  @override
  String toString() {
    return r'dmStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DmStream create() => DmStream();

  @override
  bool operator ==(Object other) {
    return other is DmStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dmStreamHash() => r'fd9070652b8fd8bd006c55453e4500a6c06d1324';

final class DmStreamFamily extends $Family
    with
        $ClassFamilyOverride<
          DmStream,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          FutureOr<List<ChatMessage>>,
          String
        > {
  const DmStreamFamily._()
    : super(
        retry: null,
        name: r'dmStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  DmStreamProvider call(String chatPartnerId) =>
      DmStreamProvider._(argument: chatPartnerId, from: this);

  @override
  String toString() => r'dmStreamProvider';
}

abstract class _$DmStream extends $AsyncNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get chatPartnerId => _$args;

  FutureOr<List<ChatMessage>> build(String chatPartnerId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatLastSeen)
const chatLastSeenProvider = ChatLastSeenProvider._();

final class ChatLastSeenProvider
    extends $AsyncNotifierProvider<ChatLastSeen, DateTime> {
  const ChatLastSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatLastSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatLastSeenHash();

  @$internal
  @override
  ChatLastSeen create() => ChatLastSeen();
}

String _$chatLastSeenHash() => r'7dbe54d62256d72c9672650a5a0df0de3e74989a';

abstract class _$ChatLastSeen extends $AsyncNotifier<DateTime> {
  FutureOr<DateTime> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<DateTime>, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime>, DateTime>,
              AsyncValue<DateTime>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatUnreadCount)
const chatUnreadCountProvider = ChatUnreadCountProvider._();

final class ChatUnreadCountProvider
    extends $NotifierProvider<ChatUnreadCount, int> {
  const ChatUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatUnreadCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatUnreadCountHash();

  @$internal
  @override
  ChatUnreadCount create() => ChatUnreadCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$chatUnreadCountHash() => r'e2885b069602872c0f3b07eef64e6f7a99ec6a1b';

abstract class _$ChatUnreadCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatNewMessageEvent)
const chatNewMessageEventProvider = ChatNewMessageEventProvider._();

final class ChatNewMessageEventProvider
    extends $NotifierProvider<ChatNewMessageEvent, ChatMessage?> {
  const ChatNewMessageEventProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatNewMessageEventProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNewMessageEventHash();

  @$internal
  @override
  ChatNewMessageEvent create() => ChatNewMessageEvent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMessage?>(value),
    );
  }
}

String _$chatNewMessageEventHash() =>
    r'97f1a44b8e12a13737054d1a21ab1963e27a42ec';

abstract class _$ChatNewMessageEvent extends $Notifier<ChatMessage?> {
  ChatMessage? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ChatMessage?, ChatMessage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatMessage?, ChatMessage?>,
              ChatMessage?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AllAroundTallyLastSeen)
const allAroundTallyLastSeenProvider = AllAroundTallyLastSeenProvider._();

final class AllAroundTallyLastSeenProvider
    extends $AsyncNotifierProvider<AllAroundTallyLastSeen, DateTime> {
  const AllAroundTallyLastSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allAroundTallyLastSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allAroundTallyLastSeenHash();

  @$internal
  @override
  AllAroundTallyLastSeen create() => AllAroundTallyLastSeen();
}

String _$allAroundTallyLastSeenHash() =>
    r'1d5ff50bad853fabe07953138702e6c77ebdd95b';

abstract class _$AllAroundTallyLastSeen extends $AsyncNotifier<DateTime> {
  FutureOr<DateTime> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<DateTime>, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime>, DateTime>,
              AsyncValue<DateTime>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AllAroundTallyUnreadCount)
const allAroundTallyUnreadCountProvider = AllAroundTallyUnreadCountProvider._();

final class AllAroundTallyUnreadCountProvider
    extends $NotifierProvider<AllAroundTallyUnreadCount, int> {
  const AllAroundTallyUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allAroundTallyUnreadCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allAroundTallyUnreadCountHash();

  @$internal
  @override
  AllAroundTallyUnreadCount create() => AllAroundTallyUnreadCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$allAroundTallyUnreadCountHash() =>
    r'3696310228cbfeed1184186d0b3282a56eec1cd6';

abstract class _$AllAroundTallyUnreadCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AllAroundTallyNewMessageEvent)
const allAroundTallyNewMessageEventProvider =
    AllAroundTallyNewMessageEventProvider._();

final class AllAroundTallyNewMessageEventProvider
    extends $NotifierProvider<AllAroundTallyNewMessageEvent, ChatMessage?> {
  const AllAroundTallyNewMessageEventProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allAroundTallyNewMessageEventProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allAroundTallyNewMessageEventHash();

  @$internal
  @override
  AllAroundTallyNewMessageEvent create() => AllAroundTallyNewMessageEvent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMessage?>(value),
    );
  }
}

String _$allAroundTallyNewMessageEventHash() =>
    r'bb61490fa89bf48311ca2e11a5bd9ad430f5e56a';

abstract class _$AllAroundTallyNewMessageEvent extends $Notifier<ChatMessage?> {
  ChatMessage? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ChatMessage?, ChatMessage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatMessage?, ChatMessage?>,
              ChatMessage?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatController)
const chatControllerProvider = ChatControllerProvider._();

final class ChatControllerProvider
    extends $AsyncNotifierProvider<ChatController, void> {
  const ChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatControllerHash();

  @$internal
  @override
  ChatController create() => ChatController();
}

String _$chatControllerHash() => r'53f74ecfc19b26e53010d332b0878a6176dffadd';

abstract class _$ChatController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
