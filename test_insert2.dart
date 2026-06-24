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
      'customer_id': '46aa98d6-cca2-4043-84df-59a71c9a5041',
      'title': 'Test title',
      'description': 'Test desc',
      'status': 'New',
      'priority': 'Medium',
      'category': 'Technical',
      'created_at': nowUtc,
      'updated_at': nowUtc,
      'created_by': 'Unknown',
      'completed_date': null, // test completed_date
    };
    
    print('Inserting: $data');
    final response = await supabase.from('tickets').insert(data).select().single();
    print('Success: $response');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
