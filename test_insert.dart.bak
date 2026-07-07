import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://ybmxpmsiihtasyjwxtol.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlibXhwbXNpaWh0YXN5and4dG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDExNTEsImV4cCI6MjA4NzQ3NzE1MX0.dOoJWDf4j_etF0NTq4uuaVG47e0y_pDe-AdgDRhWI68',
  );

  try {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final data = {
      'customer_id': '4513dbb3-5712-4c90-abbb-a483a9ce023a', // random uuid, might fail if foreign key exists, let's use a dummy or skip
      'title': 'Test title',
      'description': 'Test desc',
      'status': 'New',
      'priority': 'Medium',
      'category': 'Technical',
      'created_at': nowUtc,
      'updated_at': nowUtc,
      'created_by': 'Unknown',
    };
    
    // We don't have a valid customer_id, so let's just do a generic insert and see if it complains about columns or something else.
    // Actually, I can query a customer id first
    final customers = await supabase.from('customers').select('id').limit(1);
    if (customers.isNotEmpty) {
      data['customer_id'] = customers[0]['id'];
    }

    print('Inserting: $data');
    final response = await supabase.from('tickets').insert(data).select().single();
    print('Success: $response');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
