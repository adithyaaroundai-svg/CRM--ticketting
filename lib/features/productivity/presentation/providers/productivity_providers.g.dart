// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'productivity_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cannedResponses)
const cannedResponsesProvider = CannedResponsesProvider._();

final class CannedResponsesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CannedResponse>>,
          List<CannedResponse>,
          FutureOr<List<CannedResponse>>
        >
    with
        $FutureModifier<List<CannedResponse>>,
        $FutureProvider<List<CannedResponse>> {
  const CannedResponsesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cannedResponsesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cannedResponsesHash();

  @$internal
  @override
  $FutureProviderElement<List<CannedResponse>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CannedResponse>> create(Ref ref) {
    return cannedResponses(ref);
  }
}

String _$cannedResponsesHash() => r'c65eb1853baad6b555536edeed3c4a57dadb1014';

@ProviderFor(CannedResponseController)
const cannedResponseControllerProvider = CannedResponseControllerProvider._();

final class CannedResponseControllerProvider
    extends $AsyncNotifierProvider<CannedResponseController, void> {
  const CannedResponseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cannedResponseControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cannedResponseControllerHash();

  @$internal
  @override
  CannedResponseController create() => CannedResponseController();
}

String _$cannedResponseControllerHash() =>
    r'59d489696278d91b78e1d8001dc668c244740910';

abstract class _$CannedResponseController extends $AsyncNotifier<void> {
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

@ProviderFor(notifications)
const notificationsProvider = NotificationsProvider._();

final class NotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          Stream<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $StreamProvider<List<AppNotification>> {
  const NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return notifications(ref);
  }
}

String _$notificationsHash() => r'503b24f44208d2869706c3c2e282dcd7332a2a44';

@ProviderFor(NotificationController)
const notificationControllerProvider = NotificationControllerProvider._();

final class NotificationControllerProvider
    extends $AsyncNotifierProvider<NotificationController, void> {
  const NotificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationControllerHash();

  @$internal
  @override
  NotificationController create() => NotificationController();
}

String _$notificationControllerHash() =>
    r'de01251576ad049932f93f8bc246bd01fbad7da1';

abstract class _$NotificationController extends $AsyncNotifier<void> {
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

@ProviderFor(articles)
const articlesProvider = ArticlesProvider._();

final class ArticlesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Article>>,
          List<Article>,
          FutureOr<List<Article>>
        >
    with $FutureModifier<List<Article>>, $FutureProvider<List<Article>> {
  const ArticlesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articlesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articlesHash();

  @$internal
  @override
  $FutureProviderElement<List<Article>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Article>> create(Ref ref) {
    return articles(ref);
  }
}

String _$articlesHash() => r'e952589b7c63b402cbf8ecb60a01c657cb3e5b35';

@ProviderFor(article)
const articleProvider = ArticleFamily._();

final class ArticleProvider
    extends
        $FunctionalProvider<AsyncValue<Article?>, Article?, FutureOr<Article?>>
    with $FutureModifier<Article?>, $FutureProvider<Article?> {
  const ArticleProvider._({
    required ArticleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'articleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articleHash();

  @override
  String toString() {
    return r'articleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Article?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Article?> create(Ref ref) {
    final argument = this.argument as String;
    return article(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArticleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleHash() => r'e882ecee8cf30122912e12a0f425227fc1287c38';

final class ArticleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Article?>, String> {
  const ArticleFamily._()
    : super(
        retry: null,
        name: r'articleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ArticleProvider call(String articleId) =>
      ArticleProvider._(argument: articleId, from: this);

  @override
  String toString() => r'articleProvider';
}

@ProviderFor(ArticleController)
const articleControllerProvider = ArticleControllerProvider._();

final class ArticleControllerProvider
    extends $AsyncNotifierProvider<ArticleController, void> {
  const ArticleControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleControllerHash();

  @$internal
  @override
  ArticleController create() => ArticleController();
}

String _$articleControllerHash() => r'3fb48f7b7ff4034f2befd2256f65489862a484f4';

abstract class _$ArticleController extends $AsyncNotifier<void> {
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

@ProviderFor(deals)
const dealsProvider = DealsProvider._();

final class DealsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Deal>>,
          List<Deal>,
          Stream<List<Deal>>
        >
    with $FutureModifier<List<Deal>>, $StreamProvider<List<Deal>> {
  const DealsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dealsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dealsHash();

  @$internal
  @override
  $StreamProviderElement<List<Deal>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Deal>> create(Ref ref) {
    return deals(ref);
  }
}

String _$dealsHash() => r'09a53a6122972e2b08c3c6d9a1f56bba802877a8';

@ProviderFor(DealController)
const dealControllerProvider = DealControllerProvider._();

final class DealControllerProvider
    extends $AsyncNotifierProvider<DealController, void> {
  const DealControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dealControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dealControllerHash();

  @$internal
  @override
  DealController create() => DealController();
}

String _$dealControllerHash() => r'39463fb545b1504fcb009447d0474669dc55e646';

abstract class _$DealController extends $AsyncNotifier<void> {
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
