// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketRepository)
const ticketRepositoryProvider = TicketRepositoryProvider._();

final class TicketRepositoryProvider
    extends
        $FunctionalProvider<
          TicketRepository,
          TicketRepository,
          TicketRepository
        >
    with $Provider<TicketRepository> {
  const TicketRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketRepositoryHash();

  @$internal
  @override
  $ProviderElement<TicketRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TicketRepository create(Ref ref) {
    return ticketRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketRepository>(value),
    );
  }
}

String _$ticketRepositoryHash() => r'cd2c6929ca0d33175908435a94f6d5e0691e8394';

@ProviderFor(TicketFilter)
const ticketFilterProvider = TicketFilterProvider._();

final class TicketFilterProvider
    extends $NotifierProvider<TicketFilter, String?> {
  const TicketFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketFilterHash();

  @$internal
  @override
  TicketFilter create() => TicketFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$ticketFilterHash() => r'72644ea157be4b98d4740e9c1d8cd8b790e84cdc';

abstract class _$TicketFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TicketSearchQuery)
const ticketSearchQueryProvider = TicketSearchQueryProvider._();

final class TicketSearchQueryProvider
    extends $NotifierProvider<TicketSearchQuery, String> {
  const TicketSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketSearchQueryHash();

  @$internal
  @override
  TicketSearchQuery create() => TicketSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$ticketSearchQueryHash() => r'7270d23ddcc504d4fcdbcbbdeeb5c1633145ba92';

abstract class _$TicketSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TicketPriorityFilter)
const ticketPriorityFilterProvider = TicketPriorityFilterProvider._();

final class TicketPriorityFilterProvider
    extends $NotifierProvider<TicketPriorityFilter, String> {
  const TicketPriorityFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketPriorityFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketPriorityFilterHash();

  @$internal
  @override
  TicketPriorityFilter create() => TicketPriorityFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$ticketPriorityFilterHash() =>
    r'4f8c97a4ce99739220722ab5bd836ed1807b45ff';

abstract class _$TicketPriorityFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TicketAssigneeFilter)
const ticketAssigneeFilterProvider = TicketAssigneeFilterProvider._();

final class TicketAssigneeFilterProvider
    extends $NotifierProvider<TicketAssigneeFilter, String> {
  const TicketAssigneeFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketAssigneeFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketAssigneeFilterHash();

  @$internal
  @override
  TicketAssigneeFilter create() => TicketAssigneeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$ticketAssigneeFilterHash() =>
    r'195d73e1d5236d92ec1dfb59de31e6920b7d040a';

abstract class _$TicketAssigneeFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TicketSort)
const ticketSortProvider = TicketSortProvider._();

final class TicketSortProvider extends $NotifierProvider<TicketSort, String> {
  const TicketSortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketSortProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketSortHash();

  @$internal
  @override
  TicketSort create() => TicketSort();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$ticketSortHash() => r'e20adae48add1b6b964a8ba4d5d0f5cacca62344';

abstract class _$TicketSort extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(rawTicketsStream)
const rawTicketsStreamProvider = RawTicketsStreamProvider._();

final class RawTicketsStreamProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<List<Ticket>>,
          List<Ticket>,
          Stream<List<Ticket>>
        >
    with $FutureModifier<List<Ticket>>, $StreamProvider<List<Ticket>> {
  const RawTicketsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rawTicketsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rawTicketsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Ticket>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Ticket>> create(Ref ref) {
    return rawTicketsStream(ref);
  }
}

String _$rawTicketsStreamHash() => r'24e04c18b455e97af3fc0d48ed8cfddc8c496e36';

@ProviderFor(ticketsStream)
const ticketsStreamProvider = TicketsStreamProvider._();

final class TicketsStreamProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<List<Ticket>>,
          fr.AsyncValue<List<Ticket>>,
          fr.AsyncValue<List<Ticket>>
        >
    with $Provider<fr.AsyncValue<List<Ticket>>> {
  const TicketsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketsStreamHash();

  @$internal
  @override
  $ProviderElement<fr.AsyncValue<List<Ticket>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  fr.AsyncValue<List<Ticket>> create(Ref ref) {
    return ticketsStream(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(fr.AsyncValue<List<Ticket>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<fr.AsyncValue<List<Ticket>>>(value),
    );
  }
}

String _$ticketsStreamHash() => r'214cffe57b82e2685ebb34424d6a2c307713d187';

@ProviderFor(rawAllTicketsStream)
const rawAllTicketsStreamProvider = RawAllTicketsStreamProvider._();

final class RawAllTicketsStreamProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<List<Ticket>>,
          List<Ticket>,
          Stream<List<Ticket>>
        >
    with $FutureModifier<List<Ticket>>, $StreamProvider<List<Ticket>> {
  const RawAllTicketsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rawAllTicketsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rawAllTicketsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Ticket>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Ticket>> create(Ref ref) {
    return rawAllTicketsStream(ref);
  }
}

String _$rawAllTicketsStreamHash() =>
    r'173088d1ee1525060e854d43ca0e981cc724a077';

@ProviderFor(allTicketsStream)
const allTicketsStreamProvider = AllTicketsStreamProvider._();

final class AllTicketsStreamProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<List<Ticket>>,
          fr.AsyncValue<List<Ticket>>,
          fr.AsyncValue<List<Ticket>>
        >
    with $Provider<fr.AsyncValue<List<Ticket>>> {
  const AllTicketsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allTicketsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allTicketsStreamHash();

  @$internal
  @override
  $ProviderElement<fr.AsyncValue<List<Ticket>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  fr.AsyncValue<List<Ticket>> create(Ref ref) {
    return allTicketsStream(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(fr.AsyncValue<List<Ticket>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<fr.AsyncValue<List<Ticket>>>(value),
    );
  }
}

String _$allTicketsStreamHash() => r'cc5df8fb97a4994fe6b2e4f6a4fbb689a97eb6dc';

@ProviderFor(ticketCustomer)
const ticketCustomerProvider = TicketCustomerFamily._();

final class TicketCustomerProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  const TicketCustomerProvider._({
    required TicketCustomerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ticketCustomerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketCustomerHash();

  @override
  String toString() {
    return r'ticketCustomerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as String;
    return ticketCustomer(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketCustomerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketCustomerHash() => r'3aa5230afcb10cf947d5de86c6439d13eda15b8d';

final class TicketCustomerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>?>, String> {
  const TicketCustomerFamily._()
    : super(
        retry: null,
        name: r'ticketCustomerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TicketCustomerProvider call(String customerId) =>
      TicketCustomerProvider._(argument: customerId, from: this);

  @override
  String toString() => r'ticketCustomerProvider';
}

@ProviderFor(ticketStats)
const ticketStatsProvider = TicketStatsProvider._();

final class TicketStatsProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  const TicketStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketStatsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return ticketStats(ref);
  }
}

String _$ticketStatsHash() => r'520f5f34b8a9958a013fac743b95b9f6e9876a65';

@ProviderFor(agentsList)
const agentsListProvider = AgentsListProvider._();

final class AgentsListProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  const AgentsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentsListHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return agentsList(ref);
  }
}

String _$agentsListHash() => r'f5ba0a42e3dc2fbc79df6b966eed3d01fefbc0d0';

@ProviderFor(ticketAssignedAgent)
const ticketAssignedAgentProvider = TicketAssignedAgentFamily._();

final class TicketAssignedAgentProvider
    extends
        $FunctionalProvider<
          fr.AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  const TicketAssignedAgentProvider._({
    required TicketAssignedAgentFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'ticketAssignedAgentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketAssignedAgentHash();

  @override
  String toString() {
    return r'ticketAssignedAgentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as String?;
    return ticketAssignedAgent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketAssignedAgentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketAssignedAgentHash() =>
    r'b729d300d6df005df0bd743ff42827ab07d90d29';

final class TicketAssignedAgentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>?>, String?> {
  const TicketAssignedAgentFamily._()
    : super(
        retry: null,
        name: r'ticketAssignedAgentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TicketAssignedAgentProvider call(String? agentId) =>
      TicketAssignedAgentProvider._(argument: agentId, from: this);

  @override
  String toString() => r'ticketAssignedAgentProvider';
}

@ProviderFor(TicketStatusUpdater)
const ticketStatusUpdaterProvider = TicketStatusUpdaterProvider._();

final class TicketStatusUpdaterProvider
    extends $NotifierProvider<TicketStatusUpdater, bool> {
  const TicketStatusUpdaterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketStatusUpdaterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketStatusUpdaterHash();

  @$internal
  @override
  TicketStatusUpdater create() => TicketStatusUpdater();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ticketStatusUpdaterHash() =>
    r'db5e9775a3ae0e5a618f623ff1a9c096dad3baf5';

abstract class _$TicketStatusUpdater extends $Notifier<bool> {
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

@ProviderFor(TicketAssigner)
const ticketAssignerProvider = TicketAssignerProvider._();

final class TicketAssignerProvider
    extends $NotifierProvider<TicketAssigner, bool> {
  const TicketAssignerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketAssignerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketAssignerHash();

  @$internal
  @override
  TicketAssigner create() => TicketAssigner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ticketAssignerHash() => r'5f2d92f2145cb727ebc2417898002e5b0a2d3e9d';

abstract class _$TicketAssigner extends $Notifier<bool> {
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

@ProviderFor(TicketCreator)
const ticketCreatorProvider = TicketCreatorProvider._();

final class TicketCreatorProvider
    extends $NotifierProvider<TicketCreator, bool> {
  const TicketCreatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketCreatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketCreatorHash();

  @$internal
  @override
  TicketCreator create() => TicketCreator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ticketCreatorHash() => r'31d801c9c0bfd519e8d2625c42bd19e2d3bcdd27';

abstract class _$TicketCreator extends $Notifier<bool> {
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

@ProviderFor(TicketUpdater)
const ticketUpdaterProvider = TicketUpdaterProvider._();

final class TicketUpdaterProvider
    extends $NotifierProvider<TicketUpdater, bool> {
  const TicketUpdaterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketUpdaterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketUpdaterHash();

  @$internal
  @override
  TicketUpdater create() => TicketUpdater();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ticketUpdaterHash() => r'18e9e332880d07dc4bfdc6a98503f7d5469e8625';

abstract class _$TicketUpdater extends $Notifier<bool> {
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
