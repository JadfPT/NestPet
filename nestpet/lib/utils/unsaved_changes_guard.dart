class UnsavedChangesGuard {
  final bool Function() hasUnsaved;
  final Future<bool> Function() confirmDiscard;

  UnsavedChangesGuard({required this.hasUnsaved, required this.confirmDiscard});
}

class UnsavedChangesRegistry {
  UnsavedChangesRegistry._();
  static final UnsavedChangesRegistry instance = UnsavedChangesRegistry._();

  UnsavedChangesGuard? _guard;

  void register(UnsavedChangesGuard guard) {
    _guard = guard;
  }

  void clear(UnsavedChangesGuard guard) {
    if (identical(_guard, guard)) {
      _guard = null;
    }
  }

  Future<bool> maybeConfirmNavigation() async {
    final guard = _guard;
    if (guard == null) return true;
    if (!guard.hasUnsaved()) return true;
    return await guard.confirmDiscard();
  }
}
