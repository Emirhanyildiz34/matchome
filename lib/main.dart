import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Supabase URL ve Key alındığında aktifleştirilecek
   await Supabase.initialize(
     url: 'https://owalhgozebvapuubsgtv.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93YWxoZ296ZWJ2YXB1dWJzZ3R2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0Mzk4MDYsImV4cCI6MjA4ODAxNTgwNn0.mF7hUM-rxNaaBlh0wzrIqTZoNF_gew7rTTzsv2AY0fQ',
   );

  runApp(
    const ProviderScope(
      child: MatchHomeApp(),
    ),
  );
}
