// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, Agent?> {
  const AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Agent? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Agent?>(value),
    );
  }
}

String _$authNotifierHash() => r'7e40b9c433f1c26e34999d2cab1804d7d18919b7';

abstract class _$AuthNotifier extends $Notifier<Agent?> {
  Agent? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Agent?, Agent?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Agent?, Agent?>,
              Agent?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
