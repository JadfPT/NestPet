class MediaItem {
  String path; // caminho local ou URL
  String type; // "image" | "video"
  MediaItem({required this.path, required this.type});

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        path: j['path'] ?? '',
        type: j['type'] ?? 'image',
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'type': type,
      };
}

class Animal {
  String id;
  String nome;
  String tipo;
  String sexo;
  int idadeMeses;
  double pesoKg;
  String tamanho;
  String descricao;
  String personalidade;
  int expectativaVidaAnos;
  bool vacinado;
  String caracteristicas;
  String cor;
  List<MediaItem> media;

  Animal({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.sexo,
    required this.idadeMeses,
    required this.pesoKg,
    required this.tamanho,
    required this.descricao,
    this.personalidade = '',
    this.expectativaVidaAnos = 0,
    this.vacinado = false,
    this.caracteristicas = '',
    this.cor = '',
    required this.media,
  });

  factory Animal.fromJson(Map<String, dynamic> j) => Animal(
        id: j['id']?.toString() ?? '',
        nome: j['nome'] ?? j['name'] ?? '',
        tipo: j['tipo'] ?? j['type'] ?? 'Cão',
        sexo: j['sexo'] ?? j['sex'] ?? 'M',
        idadeMeses: (j['idadeMeses'] ?? 0) is int ? (j['idadeMeses'] ?? 0) as int : int.tryParse((j['idadeMeses'] ?? '0').toString()) ?? 0,
        pesoKg: (j['pesoKg'] ?? 0.0) is double ? (j['pesoKg'] ?? 0.0) as double : double.tryParse((j['pesoKg'] ?? '0').toString()) ?? 0.0,
        tamanho: j['tamanho'] ?? 'médio',
        descricao: j['descricao'] ?? j['description'] ?? '',
        personalidade: j['personality'] ?? j['personalidade'] ?? '',
        expectativaVidaAnos: (j['life_expectancy_years'] ?? j['expectativaVidaAnos'] ?? 0) is int
            ? (j['life_expectancy_years'] ?? j['expectativaVidaAnos'] ?? 0) as int
            : int.tryParse((j['life_expectancy_years'] ?? j['expectativaVidaAnos'] ?? '0').toString()) ?? 0,
        vacinado: (j['vaccinated'] ?? j['vacinado'] ?? false) is bool ? (j['vaccinated'] ?? j['vacinado'] ?? false) as bool : (j['vaccinated'] ?? j['vacinado'] ?? 'false').toString().toLowerCase() == 'true',
        caracteristicas: j['characteristics'] ?? j['caracteristicas'] ?? '',
        cor: j['color'] ?? j['cor'] ?? '',
        media: (j['media'] ?? []).map<MediaItem>((m) {
          if (m is MediaItem) return m;
          if (m is String) return MediaItem(path: m, type: m.endsWith('.mp4') ? 'video' : 'image');
          if (m is Map<String, dynamic>) return MediaItem.fromJson(m);
          return MediaItem(path: m.toString(), type: 'image');
        }).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo,
        'sexo': sexo,
        'idadeMeses': idadeMeses,
        'pesoKg': pesoKg,
        'tamanho': tamanho,
      'descricao': descricao,
      'personality': personalidade,
      'life_expectancy_years': expectativaVidaAnos,
      'vaccinated': vacinado,
      'characteristics': caracteristicas,
      'color': cor,
      'media': media.map((m) => m.toJson()).toList(),
      };
}
