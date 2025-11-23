import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  final _client = Supabase.instance.client;
  final String bucket = 'animal-images';

  /// Faz upload de um ficheiro e devolve a public URL (ou lança em caso de erro).
  Future<String> uploadAnimalImage(File file, String destPath) async {
    // Verifica se o cliente está autenticado — uploads exigem role 'authenticated'
    final current = _client.auth.currentUser;
    if (current == null) {
      throw Exception('Usuário não autenticado. Faça login antes de enviar imagens.');
    }

    final bytes = await file.readAsBytes();
    // Debug: mostrar qual o user id que está a tentar enviar
    // Isso ajuda a confirmar que o cliente está autenticado correctamente.
    // ignore: avoid_print
    print('StorageRepository: current user id=${current.id}');
    // Faz um retry simples (2 tentativas) para problemas temporários de rede.
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await _client.storage.from(bucket).uploadBinary(destPath, bytes, fileOptions: FileOptions(cacheControl: '3600'));
        final url = _client.storage.from(bucket).getPublicUrl(destPath);
        return url;
      } catch (e, st) {
        // Log detalhado para debugging
        // ignore: avoid_print
        print('StorageRepository.uploadAnimalImage attempt $attempt failed: $e');
        // ignore: avoid_print
        print(st);
        if (attempt == 2) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    // nunca acontece, mas para satisfazer o compilador
    throw Exception('Upload failed');
  }

  /// Gera URL assinada (opcional) para ficheiros privados
  Future<String?> createSignedUrl(String path, {int expiresIn = 3600}) async {
    try {
      final signed = await _client.storage.from(bucket).createSignedUrl(path, expiresIn);
      return signed;
    } catch (e) {
      rethrow;
    }
  }
}
