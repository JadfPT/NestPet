class Message {
  final String id;
  final String from; // "user" | "org"
  final String text;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.from,
    required this.text,
    required this.sentAt,
  });
}
