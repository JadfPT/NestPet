
// Propósito geral: Este ficheiro centraliza a configuração do cliente Supabase usada pela app,
// incluindo URL do projeto, chave pública (anon) e o esquema de redirecionamento para fluxos
// de autenticação (ex.: recuperação de palavra-passe). Mantê-las num único sítio facilita
// a reutilização e mudanças futuras.
// Observações:
// - A chave anon é pública e serve apenas para operações permitidas pelas políticas (RLS) do Supabase.
// - Nunca colocar aqui chaves de serviço (service_role) ou segredos privados.
// - O valor de redirectTo deve corresponder ao esquema/deep link configurado na app (Android/iOS/web).

// Classe de configuração do Supabase. Agrupa constantes para fácil acesso em toda a app.
class SupabaseConfig {
  // URL do projeto Supabase (endpoint base). Usado para inicializar o cliente.
  static const url = 'https://xyadeobtprdsmxfarkil.supabase.co';

  // Chave pública (anon). Permite aceder às APIs do Supabase, limitada pelas regras de segurança.
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5YWRlb2J0cHJkc214ZmFya2lsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NzI4NzAsImV4cCI6MjA3OTQ0ODg3MH0.SKwN7Es-V4md-0ArZ2Xry8QVKMaJPE_Mu9iWyT4UJQ4';

  // URL de redirecionamento para fluxos de auth. Deve bater certo
  // com o esquema configurado nos deep links do projeto.
  static const redirectTo = 'nestpet://reset';
}
