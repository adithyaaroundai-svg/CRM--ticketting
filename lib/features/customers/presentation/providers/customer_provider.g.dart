// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customer)
const customerProvider = CustomerFamily._();

final class CustomerProvider
    extends
        $FunctionalProvider<
          AsyncValue<Customer?>,
          Customer?,
          FutureOr<Customer?>
        >
    with $FutureModifier<Customer?>, $FutureProvider<Customer?> {
  const CustomerProvider._({
    required CustomerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerHash();

  @override
  String toString() {
    return r'customerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Customer?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Customer?> create(Ref ref) {
    final argument = this.argument as String;
    return customer(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerHash() => r'f518db525e7f29195a88d63f8a07267551370dde';

final class CustomerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Customer?>, String> {
  const CustomerFamily._()
    : super(
        retry: null,
        name: r'customerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerProvider call(String customerId) =>
      CustomerProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerProvider';
}

@ProviderFor(amcStats)
const amcStatsProvider = AmcStatsProvider._();

final class AmcStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  const AmcStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'amcStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$amcStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return amcStats(ref);
  }
}

String _$amcStatsHash() => r'ff572b78b7115bce43e3b6b41523c692aabe25d8';

@ProviderFor(customersList)
const customersListProvider = CustomersListProvider._();

final class CustomersListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Customer>>,
          List<Customer>,
          FutureOr<List<Customer>>
        >
    with $FutureModifier<List<Customer>>, $FutureProvider<List<Customer>> {
  const CustomersListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customersListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customersListHash();

  @$internal
  @override
  $FutureProviderElement<List<Customer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Customer>> create(Ref ref) {
    return customersList(ref);
  }
}

String _$customersListHash() => r'805efc0d5a86dddd831cc22f12cb04e304bac57b';
