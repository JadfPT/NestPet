// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'animal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 10;

  @override
  MediaItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaItem(
      path: fields[0] as String,
      type: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnimalAdapter extends TypeAdapter<Animal> {
  @override
  final int typeId = 11;

  @override
  Animal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Animal(
      id: fields[0] as String,
      nome: fields[1] as String,
      tipo: fields[2] as String,
      sexo: fields[3] as String,
      idadeMeses: fields[4] as int,
      pesoKg: fields[5] as double,
      tamanho: fields[6] as String,
      descricao: fields[7] as String,
      media: (fields[8] as List).cast<MediaItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, Animal obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.sexo)
      ..writeByte(4)
      ..write(obj.idadeMeses)
      ..writeByte(5)
      ..write(obj.pesoKg)
      ..writeByte(6)
      ..write(obj.tamanho)
      ..writeByte(7)
      ..write(obj.descricao)
      ..writeByte(8)
      ..write(obj.media);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
