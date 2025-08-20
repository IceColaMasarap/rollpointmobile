// lib/env.dart
const supabaseUrl = 'https://ndkzicvwclpxwzypvdcq.supabase.co';
// Read the anon key from --dart-define so it’s not hardcoded
const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
