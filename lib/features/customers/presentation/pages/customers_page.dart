import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_list_item.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class CustomersPage extends ConsumerStatefulWidget {
  final String initialFilter;

  const CustomersPage({super.key, this.initialFilter = 'All'});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _searchQuery = '';
  late String _amcFilter;
  bool _expandedListView = false;

  @override
  void initState() {
    super.initState();
    _amcFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return MainLayout(
      currentPath: '/customers',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Customers',
                subtitle: 'Company directory',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _expandedListView = !_expandedListView,
                      ),
                      icon: Icon(
                        _expandedListView
                            ? LucideIcons.minimize2
                            : LucideIcons.maximize2,
                        size: 16,
                      ),
                      label: Text(
                        _expandedListView ? 'Compact Cards' : 'Expand Cards',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/customers/add'),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Add Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSearchAndFilters(),
              const SizedBox(height: 16),
              Expanded(
                child: ticketsAsync.when(
                  data: (tickets) {
                    final pendingBillCustomerIds = tickets
                        .where((t) => t.status == 'BillRaised')
                        .map((t) => t.customerId)
                        .toSet();

                    return customersAsync.when(
                      data: (customers) {
                        final filtered = customers.where((customer) {
                          final matchesSearch =
                              _searchQuery.isEmpty ||
                              customer.companyName.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              );

                          final hasAmc = customer.amcExpiryDate != null;

                          final matchesFilter =
                              _amcFilter == 'All' ||
                              (_amcFilter == 'Active' &&
                                  hasAmc &&
                                  customer.isAmcActive) ||
                              (_amcFilter == 'Expired' &&
                                  hasAmc &&
                                  !customer.isAmcActive) ||
                              (_amcFilter == 'Pending Bills' &&
                                  pendingBillCustomerIds.contains(
                                    customer.id,
                                  )) ||
                              (_amcFilter == 'Pinned' &&
                                  (customer.pinnedNote != null &&
                                      customer.pinnedNote!.trim().isNotEmpty));

                          return matchesSearch && matchesFilter;
                        }).toList();

                        if (filtered.isEmpty) {
                          return const EmptyStateCard(
                            icon: LucideIcons.users,
                            title: 'No customers found',
                            subtitle: 'Try adjusting your filters',
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final customer = filtered[index];
                            return CustomerListItem(
                              customer: customer,
                              expanded: _expandedListView,
                              onTap: () =>
                                  context.push('/customer/${customer.id}'),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Center(child: Text('Error loading customers: $err')),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Error loading tickets: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchBar(
          hintText: 'Search customers...',
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 12),
        FilterChipGroup(
          options: const [
            'All',
            'Active',
            'Expired',
            'Pending Bills',
            'Pinned',
          ],
          selected: _amcFilter,
          onSelected: (value) {
            setState(() {
              _amcFilter = value ?? 'All';
            });
          },
        ),
      ],
    );
  }
}
