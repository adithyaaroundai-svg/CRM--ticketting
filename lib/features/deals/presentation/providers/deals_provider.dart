import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Deal {
  final String id;
  final String name;
  final String date;
  final String remark;
  final String phoneNumber;

  Deal({
    required this.id,
    required this.name,
    required this.date,
    required this.remark,
    required this.phoneNumber,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
    );
  }
}

final dealsProvider = FutureProvider<List<Deal>>((ref) async {
  final data = await Supabase.instance.client
      .from('deals')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((json) => Deal.fromJson(json)).toList();
});

final dealControllerProvider = AsyncNotifierProvider<DealController, void>(() {
  return DealController();
});

class DealController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addDeal({
    required String name,
    required String date,
    required String remark,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('deals').insert({
        'name': name,
        'date': date,
        'remark': remark,
        'phone_number': phoneNumber,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });
      state = const AsyncData(null);
      ref.invalidate(dealsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateDeal({
    required String id,
    required String name,
    required String date,
    required String remark,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('deals').update({
        'name': name,
        'date': date,
        'remark': remark,
        'phone_number': phoneNumber,
      }).eq('id', id);
      state = const AsyncData(null);
      ref.invalidate(dealsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
