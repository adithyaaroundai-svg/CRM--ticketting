import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/lead.dart';

/// Simple FutureProvider that fetches leads directly from database.
/// Use ref.invalidate(leadsProvider) to refresh after any change.
final leadsProvider = FutureProvider<List<Lead>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('leads')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((json) => Lead.fromJson(json)).toList();
});

// Keep backward-compatible stream alias
final leadsStreamProvider = leadsProvider;

final leadControllerProvider = AsyncNotifierProvider<LeadController, void>(() {
  return LeadController();
});

class LeadController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createLead({
    required String companyName,
    required double amount,
    String status = 'pending',
  }) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('leads').insert({
        'company_name': companyName,
        'amount': amount,
        'status': status,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });
      state = const AsyncData(null);
      // Refresh the leads list after successful insert
      ref.invalidate(leadsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateLeadStatus(String leadId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('leads')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', leadId);
      // Refresh the leads list after update
      ref.invalidate(leadsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteLead(String leadId) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('leads').delete().eq('id', leadId);
      state = const AsyncData(null);
      // Refresh the leads list after delete
      ref.invalidate(leadsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
