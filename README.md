# 🐾 NestPet

> Plataforma móvel de adoção e gestão de animais desenvolvida em Flutter com backend Supabase.

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)

---

## 📖 Sobre o Projeto

**NestPet** é uma aplicação móvel multiplataforma (Android, iOS, Web) que conecta pessoas interessadas em adotar animais com organizações de resgate e abrigos. A plataforma oferece:

- 🔍 **Pesquisa avançada** com filtros como espécie, sexo, idade, peso, cor, tamanho e estado de vacinação
- ⭐ **Sistema de favoritos** para guardar animais de interesse
- 💬 **Chat em tempo real** entre utilizadores e organizações
- 📸 **Galeria multimedia** com suporte a fotos e vídeos
- 👤 **Três tipos de conta**: Convidado, Utilizador e Organização
- 🔐 **Autenticação segura** via Supabase Auth

---

## 🎯 Funcionalidades por Tipo de Conta

### 🚶 Convidado (Guest)
- Navegar e pesquisar animais disponíveis
- Visualizar detalhes completos dos animais
- Acesso limitado: **não pode** favoritar, contactar instituições ou editar perfil
- Ao tentar ações restritas, recebe convite para criar conta

### 👥 Utilizador (User)
- Todas as funcionalidades de Convidado, mais:
- ⭐ Adicionar animais aos favoritos
- 💬 Contactar instituições via chat em tempo real
- ✏️ Editar perfil (nome e avatar)
- 📱 Receber notificações de mensagens

### 🏢 Organização (Org)
- ➕ Adicionar novos animais para adoção
- ✏️ Editar informações de animais existentes
- 🗑️ Remover animais já adotados
- 💬 Comunicar com utilizadores interessados
- 🏛️ Gestão de informações institucionais (nome, morada, horários, contactos, website)
- 📊 Visualizar todos os animais publicados pela organização

---

## 🏗️ Arquitetura e Tecnologias

### Stack Principal
- **Flutter 3.9.2+** - Framework UI multiplataforma
- **Dart 3.0+** - Linguagem de programação
- **Supabase** - Backend-as-a-Service (BaaS)
  - PostgreSQL (Base de dados)
  - Supabase Auth (Autenticação)
  - Supabase Storage (Armazenamento de imagens/vídeos)
  - Realtime (Chat em tempo real)

### Padrões de Projeto
- **Provider** - Gestão de estado reativo
- **Repository Pattern** - Abstração de acesso a dados
- **GoRouter** - Navegação declarativa com shell routes
- **MVC adaptado** - Separação de lógica e UI

---

## 📁 Estrutura de Ficheiros

```
lib/
├── main.dart                    # Ponto de entrada da aplicação
├── app_router.dart              # Configuração de rotas (GoRouter)
├── supabase_config.dart         # Configuração do cliente Supabase
│
├── models/                      # Modelos de dados
│   ├── animal.dart              # Modelo Animal (espécie, raça, idade, etc.)
│   ├── message.dart             # Modelo Message (chat)
│   └── organization.dart        # Modelo Organization
│
├── providers/                   # Gestão de estado (Provider)
│   └── app_state.dart           # Estado global (auth, animais, favoritos)
│
├── data/                        # Repositórios de dados
│   ├── supabase_animal_repository.dart    # CRUD de animais
│   ├── supabase_chat_repository.dart      # Chat em tempo real
│   ├── supabase_favorites_repository.dart # Sistema de favoritos
│   └── storage_repository.dart            # Upload de media
│
├── services/                    # Serviços auxiliares
│   ├── session_service.dart     # Persistência de sessão local
│   └── auth_service.dart        # Autenticação e gestão de utilizadores
│
├── screens/                     # Ecrãs da aplicação
│   ├── auth/                    # Autenticação
│   │   ├── welcome_screen.dart           # Ecrã inicial
│   │   ├── login_screen.dart             # Login
│   │   ├── register_user_screen.dart     # Registo utilizador
│   │   └── register_org_screen.dart      # Registo organização
│   │
│   ├── user/                    # Ecrãs de utilizador
│   │   ├── user_home_screen.dart         # Home com grid de animais
│   │   ├── animal_detail_screen.dart     # Detalhes do animal
│   │   ├── animal_filters_sheet.dart     # Bottom sheet de filtros
│   │   ├── favorites_screen.dart         # Lista de favoritos
│   │   ├── profile_screen.dart           # Perfil do utilizador
│   │   └── chat_screen.dart              # Chat com organização
│   │
│   ├── org/                     # Ecrãs de organização
│   │   ├── org_home_screen.dart          # Home com animais da org
│   │   ├── add_animal_screen.dart        # Adicionar animal
│   │   ├── edit_animal_screen.dart       # Editar animal
│   │   ├── edit_org_screen.dart          # Editar dados da organização
│   │   ├── profile_screen.dart           # Perfil da organização
│   │   └── chat_screen.dart              # Chat com utilizadores
│   │
│   ├── common/                  # Ecrãs partilhados
│   │   └── edit_account_screen.dart      # Editar nome/avatar
│   │
│   └── widgets/                 # Widgets reutilizáveis
│       └── animal_grid_card.dart         # Card de animal no grid
│
├── widgets/                     # Widgets globais
│   ├── avatar_picker.dart       # Seletor de avatar com câmara/galeria
│   └── media_gallery.dart       # Galeria de imagens/vídeos
│
├── utils/                       # Utilitários
│   ├── color_tags.dart          # Lista de cores disponíveis
│   └── unsaved_changes_guard.dart # Sistema de avisos de alterações não guardadas
│
└── assets/                      # Recursos estáticos
    └── (imagens, fontes, etc.)
```

### Pastas Fora de `lib/`

```
android/          # Configuração Android nativa
ios/              # Configuração iOS nativa
web/              # Configuração Web (PWA)
  └── index.html  # HTML customizado para Web
windows/          # Configuração Windows nativa
linux/            # Configuração Linux nativa
macos/            # Configuração macOS nativa

```

---

## 🔧 Como Funciona

### 1️⃣ Autenticação
- Utilizadores e organizações criam conta com **email e password**
- Supabase envia email de confirmação com link customizado
- **Página de confirmação customizada**: [nestpet-confirm](https://github.com/Hug00x/nestpet-confirm)
  - Design consistente com a identidade visual da app
  - Hosted externamente para maior flexibilidade
- Convidados podem navegar sem criar conta (modo read-only)

### 2️⃣ Gestão de Animais
- Organizações criam anúncios com:
  - Dados base (espécie, raça, nome, sexo, idade, peso, tamanho)
  - Informações extras (vacinação, expectativa de vida, personalidade, descrição)
  - Multimedia (fotos e vídeos curtos)
  - Cores (suporte a múltiplas cores via CSV)
- Sistema de storage do Supabase armazena media no bucket `animal-images`

### 3️⃣ Pesquisa e Filtros
- **Pesquisa textual** por nome ou descrição
- **Filtros avançados**:
  - Espécie (Cão, Gato, Outro)
  - Sexo (Macho/Fêmea/Indiferente)
  - Idade (meses ou anos)
  - Peso (0-100 kg com slider)
  - Cor (seleção múltipla)
  - Tamanho (Pequeno, Médio, Grande)
  - Vacinado (Sim/Não/Indiferente)
- Filtros aplicados em tempo real no cliente

### 4️⃣ Sistema de Favoritos
- Utilizadores autenticados guardam animais de interesse
- Sincronização com Supabase (tabela `favorites`)
- Acesso rápido via tab "Favoritos"
- Ícone de estrela animado com feedback visual

### 5️⃣ Chat em Tempo Real
- Canal direto entre utilizador e organização
- Baseado em Supabase Realtime (WebSockets)
- Indicador de "a escrever..." (typing status)
- Histórico de mensagens persistente
- UI com estilo simples mas moderno

### 6️⃣ Proteções para Convidados
- Sistema de diálogos informativos ao tentar:
  - Adicionar favoritos → "Para adicionar favoritos, precisa de criar uma conta"
  - Contactar instituição → "Para contactar a instituição, precisa de criar uma conta"
  - Editar perfil → "Para editar o perfil, precisa de criar uma conta"
- Botão direto para registo na modal

### 7️⃣ Navegação
- **Shell routes** com bottom navigation bar customizado (pill-style)
- Navegação contextual por role (User vs Org)
- Avisos de alterações não guardadas ao tentar sair de formulários
- Back navigation inteligente com `WillPopScope`

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- **Flutter SDK 3.9.2+** ([Instalar Flutter](https://docs.flutter.dev/get-started/install))
- **Dart 3.0+** (incluído no Flutter)
- **Git** ([Instalar Git](https://git-scm.com/downloads))
- **Dispositivo/Emulador** (Android, iOS ou Browser para Web)

### Passo 1: Clonar o Repositório
```bash
git clone https://github.com/JadfPT/NestPet.git
cd NestPet/nestpet
```

### Passo 2: Instalar Dependências
```bash
flutter pub get
```

### Passo 3: Executar a Aplicação

A aplicação já tem o backend Supabase configurado, bastando apenas executar o app:

#### Android (Emulador ou Dispositivo)
```bash
flutter run
```

#### iOS (requer macOS e Xcode)
```bash
flutter run -d ios
```

#### Web (Browser)
```bash
flutter run -d chrome
```

#### Windows
```bash
flutter run -d windows
```

### Passo 4: Testar a App

Uma vez que a app está em execução, pode:

1. **Entrar como Convidado** - Clique em "Entrar como Convidado" para navegar sem criar conta
2. **Criar Conta de Utilizador** - Registe-se com email/password para testar favoritos e chat
3. **Criar Conta de Organização** - Registe-se como organização para adicionar/editar animais
4. **Pesquisar Animais** - Use a home screen para navegar e filtrar por espécie, raça, peso, etc.
5. **Testar Chat** - Contacte uma organização para testar mensageria em tempo real
6. **Adicionar Favoritos** - Guarde animais de interesse (apenas com conta de utilizador)

> **Nota**: O email de confirmação enviado pelo Supabase redireciona para a página de confirmação customizada em [nestpet-confirm](https://github.com/Hug00x/nestpet-confirm)

---

## 🔧 Arquitetura do Backend (Supabase)

O NestPet usa **Supabase** para toda a lógica de backend. Esta secção explica como tudo funciona:

### 🗄️ Base de Dados (PostgreSQL)

A estrutura de dados está organizada em 6 tabelas principais:

#### **animals** - Anúncios de animais
- `org_id` - ID da organização que publicou
- `especie`, `raca`, `nome`, `sexo` - Dados base
- `idade_meses`, `peso_kg`, `tamanho` - Filtros numéricos
- `vacinado` - Estado de vacinação (Sim/Não/Indiferente)
- `cor` - Cores separadas por virgula (CSV, suporta múltiplas)
- `personalidade` - Array PostgreSQL com traços de caráter
- `media` - JSONB com URLs de imagens/vídeos do Storage

#### **favorites** - Animais guardados por utilizadores
- `user_id` + `animal_id` (chave primária composta)
- Sincronizado em **tempo real** com Realtime
- Quando um utilizador guarda um animal, a estrela fica amarela instantaneamente

#### **messages** - Chat entre utilizadores e organizações
- `animal_id` - Animal sobre o qual estão a falar
- `sender_id` e `receiver_id` - Quem envia/recebe
- `sent_at` - Timestamp de envio
- Suportada por **Supabase Realtime** (WebSockets)
- Mensagens aparecem instantaneamente nas duas pontas

#### **organizations** - Dados das instituições
- `id` - Mesmo ID do utilizador (auth.users)
- `name`, `address`, `hours`, `phone`, `email`, `website`
- Permite a organização editar dados institucionais

#### **profiles** - Dados de perfil de utilizadores
- `id` - Mesmo ID do utilizador (auth.users)
- `username` - Nome customizado (com email como fallback)
- `avatar_url` - URL da imagem no Storage

#### **typing_status** - Indicador "a escrever" no chat
- Armazena quem está a escrever numa conversa específica
- Atualizado em tempo real para melhor UX

<br>

### 🔐 Autenticação (Supabase Auth)

Supabase Auth fornece:

- **Email/Password**
  - Passwords hasheadas com bcrypt
  - Tokens JWT para sessões seguras
  - Refresh automático de tokens

- **User Metadata** (armazenado em `auth.users.user_metadata`)
  ```json
  {
    "role": "user" | "org",
    "displayName": "Nome do Utilizador",
    "avatar_url": ["https://...url..."]
  }
  ```

- **Email de Confirmação Customizado**
  - Supabase gera link de confirmação
  - Link redireciona para [nestpet-confirm](https://github.com/Hug00x/nestpet-confirm)
  - Design consistente com a app em português

<br>

### 💾 Storage (Supabase Storage - S3 Compatible)

Armazena todo o conteúdo multimedia:

#### Bucket: `animal-images`
- Fotos de animais
- Vídeos curtos de apresentação
- Organizado por: `animal-images/{org_id}/{animal_id}/{media_id}`

#### Bucket: `avatars`
- Avatares de utilizadores
- Organizado por: `avatars/{user_id}/{avatar_file}`

**Políticas de acesso:**
- Leitura pública (qualquer um descarrega)
- Upload autenticado (apenas utilizadores logged-in)
- Delete autenticado (apenas o owner)

<br>

### ⚡ Realtime (WebSockets)

Supabase Realtime sincroniza dados em tempo real:

1. **Chat**
   - Quando INSERT em `messages`, todos os subscribers são notificados
   - Mensagem aparece instantaneamente no outro lado

2. **Favoritos**
   - INSERT/DELETE em `favorites` dispara update em tempo real
   - Outra aba/dispositivo vê a mudança imediatamente

3. **Typing Status**
   - UPDATE em `typing_status` notifica em tempo real
   - "A escrever..." aparece/desaparece instantaneamente

<br>

### 🌐 Como a App Comunica

A app usa `supabase_flutter` para:

**CRUD Simples:**
```dart
// Ler animais de uma organização
final animais = await supabase
    .from('animals')
    .select()
    .eq('org_id', userId);

// Guardar favorito
await supabase.from('favorites').insert({
  'user_id': userId,
  'animal_id': animalId,
});
```

**Queries em Tempo Real:**
```dart
// Subscribe a mensagens
supabase
    .from('messages')
    .on(RealtimeListenEvent.all, (payload) {
      // Nova mensagem recebida em tempo real!
      updateUI(payload.newRecord);
    })
    .subscribe();
```

**Upload de Ficheiros:**
```dart
// Enviar foto para o Storage
await supabase.storage
    .from('animal-images')
    .upload('${userId}/${animalId}/photo.jpg', file);
```

<br>

### 🔒 Segurança (Row Level Security)

Supabase usa **RLS** para garantir isolamento de dados:

```sql
-- Um utilizador só vê os seus próprios favoritos
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own favorites"
ON favorites FOR SELECT USING (auth.uid() = user_id);

-- Uma organização só edita os seus próprios animais
CREATE POLICY "Orgs edit own animals"
ON animals FOR UPDATE USING (auth.uid() = org_id);
```

<br>

### 📊 Exemplo: Fluxo de uma Mensagem

1. **Utilizador A envia mensagem**
   - App faz INSERT em `messages` com sender_id, receiver_id, text
   - JWT valida que sender_id = auth.uid()

2. **Supabase insere na base de dados**
   - RLS verifica permissões
   - Trigger atualiza `typing_status` para false

3. **Realtime notifica**
   - Todos os clients com subscription ativa em `messages` recebem evento

4. **UI de Utilizador B atualiza**
   - Mensagem aparece no chat instantaneamente
   - Indicador "a escrever" desaparece

---

## 📦 Build para Produção

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS (requer macOS e Xcode)
flutter build ios --release

# Web
flutter build web --release
```

---

## 🗄️ Sobre o Supabase

**Supabase** é uma alternativa open-source ao Firebase que fornece:

### Funcionalidades Usadas no NestPet

1. **PostgreSQL Database**
   - Armazenamento estruturado de animais, mensagens, favoritos
   - Queries SQL otimizadas
   - Relações entre tabelas (foreign keys)

2. **Supabase Auth**
   - Registo e login com email/password
   - Gestão de sessões automática
   - User metadata (role, displayName, avatar)
   - **Email de confirmação customizado** → [nestpet-confirm](https://github.com/Hug00x/nestpet-confirm)

3. **Supabase Storage**
   - Upload de imagens e vídeos
   - URLs públicos para media
   - Buckets organizados por tipo (animais, avatars)

4. **Supabase Realtime**
   - Chat em tempo real via WebSockets
   - Typing indicators
   - Sincronização instantânea de mensagens

### Página de Confirmação Customizada

O NestPet usa uma **página de confirmação de email customizada** hospedada em repositório separado:

🔗 **Repositório**: [nestpet-confirm](https://github.com/Hug00x/nestpet-confirm)

**Por que customizada?**
- Design alinhado com a identidade visual do NestPet
- Mensagens em português
- Melhor experiência do utilizador
- Hospedada externamente para maior controlo

**Configuração no Supabase**:
1. Authentication → Email Templates
2. Confirm signup → Editar template
3. Adicionar redirect URL para o repositório hospedado

---

## 🎨 Design e UI/UX

- **Material Design 3** com tema customizado
- Paleta de cores quente (tons castanhos/terra)
- Bottom navigation bar estilo "pill" com animações
- Cards com bordas arredondadas e sombras subtis
- Feedback visual em todas as interações
- Diálogos informativos para ações restritas
- Formulários com validação em tempo real

---

## 🔐 Segurança

- Senhas hasheadas pelo Supabase Auth
- Row Level Security (RLS) nas tabelas
- Tokens JWT para autenticação
- Storage policies para controle de acesso
- Validação client-side e server-side
- Sanitização de inputs

---

## 🧪 Testing

```bash
# Executar testes unitários
flutter test

# Executar testes com cobertura
flutter test --coverage

# Análise de código
flutter analyze
```

---

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^17.0.0           # Navegação declarativa
  provider: ^6.1.2             # Gestão de estado
  supabase_flutter: ^2.10.3    # Cliente Supabase
  image_picker: ^1.1.0         # Seleção de imagens
  video_player: ^2.9.1         # Reprodução de vídeos
  file_picker: ^10.3.7         # Seleção de ficheiros
  url_launcher: ^6.1.12        # Abrir URLs externas
  path_provider: ^2.1.3        # Acesso a diretórios do sistema
  shared_preferences: ^2.1.1   # Persistência local
  uuid: ^4.4.2                 # Geração de UUIDs
  app_links: ^6.4.1            # Deep links
```

---

## 🖼️ Wireframes

- Wireframes completos incluídos no repositório: `Wireframes NestPet.jpg` (ver raiz do projeto no GitHub)
- Cumprem o fluxo principal de onboarding, pesquisa, detalhe, favoritos, chat e ecrãs de organização
- Úteis para alinhamento rápido antes de navegar pelo código

---

## 📑 Relatório

- Relatório final incluído na raiz do repositório: `Relatorio_NestPet.pdf`
- Contém objetivos, arquitetura, decisões técnicas, testes e resultados

---

## 🤝 Contribuir

Projeto académico: não aceitamos contribuições externas neste repositório. Se quiser explorar ou adaptar:

1. Faça um fork/cópia do projeto
2. Trabalhe na sua cópia (branch/local)
3. Use para estudo ou demonstração
4. Aceitamos sugestões, mas sem submissão de PRs

---

## 📄 Licença

Projeto académico para a unidade curricular de Programação de Dispositivos Móveis (Engenharia Informática). Não há licença de distribuição pública; uso apenas para fins educativos e demonstração. Nenhuma garantia é fornecida.

---

## 👨‍💻 Autores

- **JadfPT** - [GitHub](https://github.com/JadfPT)
- **Hug00x** - [GitHub](https://github.com/Hug00x)
- **almeidinhos10** - [GitHub](https://github.com/almeidinhos10)
- **xandexun** - [GitHub](https://github.com/xandexun)

---

## 🙏 Agradecimentos

- Comunidade Flutter pela excelente documentação
- Equipa Supabase pelo BaaS incrível
- Todas as organizações de resgate animal que inspiraram este projeto

---

## 📞 Contacto

Para dúvidas ou sugestões:
- 📧 Email: use os contactos públicos nos perfis GitHub dos autores (ver secção Autores)
- 🐛 Issues: [GitHub Issues](https://github.com/JadfPT/NestPet/issues)

---

**Feito com ❤️ para ajudar animais a encontrar um lar**