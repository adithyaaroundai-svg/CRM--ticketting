import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../../core/utils/json_converters.dart';

part 'customer_provider.g.dart';

// Get customer by ID
@riverpod
Future<Customer?> customer(Ref ref, String customerId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  final customerData = await repository.getCustomer(customerId);

  if (customerData == null) return null;
  return Customer.fromJson(customerData);
}

// Get AMC stats for dashboard (cache for faster dashboards)
@riverpod
Future<Map<String, int>> amcStats(Ref ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);
  try {
    final response = await Supabase.instance.client
        .from('customers')
        .select('amc_expiry_date');

    int active = 0;
    int expired = 0;
    final now = DateTime.now();

    for (var customer in response) {
      final amcDate = customer['amc_expiry_date'];
      if (amcDate != null) {
        final expiry = parseUtcDate(amcDate.toString());
        if (expiry.isAfter(now)) {
          active++;
        } else {
          expired++;
        }
      }
    }

    return {'active': active, 'expired': expired};
  } catch (e) {
    return {'active': 0, 'expired': 0};
  }
}

// Get all customers for listing (fetches in batches to bypass 1k row limit)
@riverpod
Future<List<Customer>> customersList(Ref ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);
  final client = Supabase.instance.client;
  const batchSize = 1000; // Supabase REST default limit
  const selectedFields = 'id,company_name,amc_expiry_date,api_key';
  int from = 0;
  final customers = <Customer>[];

  while (true) {
    final to = from + batchSize - 1;
    final List<dynamic> response = await client
        .from('customers')
        .select(selectedFields)
        .order('company_name')
        .range(from, to);

    if (response.isEmpty) {
      break;
    }

    customers.addAll(
      response
          .cast<Map<String, dynamic>>()
          .map(Customer.fromJson),
    );

    if (response.length < batchSize) {
      break;
    }
    from += batchSize;
  }

  return customers;
}
