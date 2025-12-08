/*
Propósito: Modelo simples para representar uma mensagem de chat.
- Contém identificador, origem (user/org), texto, data de envio e leitura.
- Usado na UI de chat e nas operações de mensagens.

Observações:
- `from` é uma string curta (por exemplo, 'user' ou 'org').
- `readAt` pode ser nulo quando a mensagem ainda não foi lida.
*/
class Message {
  // Identificador único da mensagem.
  final String id;
  // Origem da mensagem: 'user' ou 'org'.
  final String from;
  // Conteúdo textual da mensagem.
  final String text;
  // Momento em que foi enviada.
  final DateTime sentAt;
  // Momento de leitura (opcional, nulo se não lida).
  final DateTime? readAt;

  Message({
    required this.id,
    required this.from,
    required this.text,
    required this.sentAt,
    this.readAt,
  });

  // Indica se a mensagem já foi lida (há timestamp de leitura).
  bool get isRead => readAt != null;
}
