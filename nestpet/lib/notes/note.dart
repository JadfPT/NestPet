class Note {
final int? id;
final String title;
final String content;
final DateTime createdAt;


Note({this.id, required this.title, required this.content, required this.createdAt});


Map<String, dynamic> toMap() => {
'id': id,
'title': title,
'content': content,
'createdAt': createdAt.millisecondsSinceEpoch,
};


factory Note.fromMap(Map<String, dynamic> map) => Note(
id: map['id'] as int?,
title: map['title'] as String,
content: map['content'] as String,
createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
);
}