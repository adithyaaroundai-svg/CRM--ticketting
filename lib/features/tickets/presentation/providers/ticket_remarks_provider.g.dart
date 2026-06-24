// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_remarks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketRemarks)
const ticketRemarksProvider = TicketRemarksFamily._();

final class TicketRemarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  const TicketRemarksProvider._({
    required TicketRemarksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ticketRemarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketRemarksHash();

  @override
  String toString() {
    return r'ticketRemarksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return ticketRemarks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketRemarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketRemarksHash() => r'9edd4f1f9aecc72d3e6353924069b11876c08c90';

final class TicketRemarksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  const TicketRemarksFamily._()
    : super(
        retry: null,
        name: r'ticketRemarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TicketRemarksProvider call(String ticketId) =>
      TicketRemarksProvider._(argument: ticketId, from: this);

  @override
  String toString() => r'ticketRemarksProvider';
}

@ProviderFor(TicketRemarksAdder)
const ticketRemarksAdderProvider = TicketRemarksAdderProvider._();

final class TicketRemarksAdderProvider
    extends $NotifierProvider<TicketRemarksAdder, bool> {
  const TicketRemarksAdderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketRemarksAdderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketRemarksAdderHash();

  @$internal
  @override
  TicketRemarksAdder create() => TicketRemarksAdder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ticketRemarksAdderHash() =>
    r'31b639df3d4055ebeb28c7f8204ad1af2c358e36';

abstract class _$TicketRemarksAdder extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
