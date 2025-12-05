/// Substitua as constantes abaixo com as credenciais do seu projeto Supabase.
/// NÃO comite chaves sensíveis em repositórios públicos.
class SupabaseConfig {
  // Exemplo: 'https://xyzcompany.supabase.co'
  static const url = 'https://xyadeobtprdsmxfarkil.supabase.co';

  // NOTE: This anon key you provided is public by design (anon). Avoid committing to public repos.
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5YWRlb2J0cHJkc214ZmFya2lsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NzI4NzAsImV4cCI6MjA3OTQ0ODg3MH0.SKwN7Es-V4md-0ArZ2Xry8QVKMaJPE_Mu9iWyT4UJQ4';
  // Optional: override redirect URL used in password reset emails.
  // Example: 'https://yourdomain.com/reset' or a deep link like 'nestpet://reset'
  // If empty, Supabase will use the project default (configured in the Supabase dashboard).
  // Default to the app's custom scheme so password reset links open the app.
  // Ensure you also add this URL in the Supabase project's "Redirect URLs" list.
  static const redirectTo = 'nestpet://reset';
}
