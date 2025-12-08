// Propósito geral: Widget de estado vazio reutilizável para indicar ausência de
// conteúdo (lista vazia, erro sem dados, etc.), com ícone, título, mensagem e
// ação opcional.
// Observações:
// - Centraliza a apresentação do estado vazio com espaçamento e largura máxima.
// - O botão de ação só aparece quando `actionText` e `onAction` são fornecidos.

import 'package:flutter/material.dart';

// Widget stateless parametrizável para mostrar estado vazio consistente na app.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Obter esquema de cores para harmonizar ícone e texto.
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          // Limita a largura para boa leitura em ecrãs largos.
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone ilustrativo do estado vazio.
              Icon(icon, size: 56, color: cs.outline),
              const SizedBox(height: 12),
              // Título destacado.
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              // Mensagem descritiva, centrada.
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              ),
              // Ação opcional: aparece apenas quando ambos existem.
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionText!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
