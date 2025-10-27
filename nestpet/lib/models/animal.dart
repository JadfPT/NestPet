import 'package:hive/hive.dart';
part 'animal.g.dart';

@HiveType(typeId: 10)
class MediaItem {
  @HiveField(0) String path;   // caminho local
  @HiveField(1) String type;   // "image" | "video"
  MediaItem({required this.path, required this.type});
}

@HiveType(typeId: 11)
class Animal extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nome;
  @HiveField(2) String tipo;
  @HiveField(3) String sexo;
  @HiveField(4) int idadeMeses;
  @HiveField(5) double pesoKg;
  @HiveField(6) String tamanho;
  @HiveField(7) String descricao;
  @HiveField(8) List<MediaItem> media;

  Animal({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.sexo,
    required this.idadeMeses,
    required this.pesoKg,
    required this.tamanho,
    required this.descricao,
    required this.media,
  });
}
