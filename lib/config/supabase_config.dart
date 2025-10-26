// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://cnugueyqwkfiyprjagdm.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNudWd1ZXlxd2tmaXlwcmphZ2RtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MTQ3OTcsImV4cCI6MjA3NjQ5MDc5N30.KZj1xbpqdQAaaVuO5HbOC9xeZsuQPHwi08fWUgjTNdQ';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      // Supabase initialized successfully
    } catch (error) {
      // Error initializing Supabase
      rethrow;
    }
  }
}
