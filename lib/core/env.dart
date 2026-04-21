class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ydxutgrcepapfuspnizt.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlkeHV0Z3JjZXBhcGZ1c3BuaXp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MTI4ODEsImV4cCI6MjA5MjI4ODg4MX0.tD4c4qo2tvp0sSKurDc3E4vP2Z-zP9MLAAYS1ex-28k',
  );
}
