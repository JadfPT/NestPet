import '../models/message.dart';

class ChatRepository {
  final Map<String, List<Message>> _threads = {};

  List<Message> forAnimal(String animalId) {
    return _threads[animalId] ??= [
      Message(id:'m1', from:'org', text:'Olá! Como posso ajudar?', sentAt: DateTime.now().subtract(Duration(minutes: 5))),
    ];
  }

  void send(String animalId, String from, String text) {
    final list = _threads[animalId] ??= [];
    list.add(Message(id: DateTime.now().millisecondsSinceEpoch.toString(), from: from, text: text, sentAt: DateTime.now()));
  }
}
