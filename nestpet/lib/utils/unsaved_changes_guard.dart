// Propósito geral: Fornecer um mecanismo simples para detetar alterações não guardadas
// e pedir confirmação ao utilizador antes de navegar/sair do ecrã.
// Observações:
// - A aplicação regista um guard (hasUnsaved/confirmDiscard) quando um ecrã tem edição.
// - O registry é singleton; apenas um guard ativo é considerado de cada vez.
// - `maybeConfirmNavigation` deve ser chamado antes de navegar para evitar perda de dados.

// Estrutura que descreve como verificar se há alterações por guardar e como confirmar descarte.
class UnsavedChangesGuard {
  final bool Function() hasUnsaved;
  final Future<bool> Function() confirmDiscard;

  UnsavedChangesGuard({required this.hasUnsaved, required this.confirmDiscard});
}

// Registo global (singleton) de um guard ativo. Permite registar/limpar e
// consultar antes de navegar.
class UnsavedChangesRegistry {
  UnsavedChangesRegistry._();
  static final UnsavedChangesRegistry instance = UnsavedChangesRegistry._();

  UnsavedChangesGuard? _guard;

  // Ativa um guard para o ecrã atual.
  void register(UnsavedChangesGuard guard) {
    _guard = guard;
  }

  // Limpa o guard se corresponder ao atualmente registado.
  void clear(UnsavedChangesGuard guard) {
    if (identical(_guard, guard)) {
      _guard = null;
    }
  }

  // Verifica se existem alterações não guardadas e, se existirem, pede confirmação.
  // Retorna true para permitir navegação, false para ficar no ecrã.
  Future<bool> maybeConfirmNavigation() async {
    final guard = _guard;
    if (guard == null) return true;
    if (!guard.hasUnsaved()) return true;
    return await guard.confirmDiscard();
  }
}
