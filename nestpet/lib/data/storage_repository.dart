/*
Propósito: Repositório para gerir uploads e URLs de media no Supabase Storage.
- Faz upload (binário) de imagens/vídeos dos animais e obtém URLs públicas/assinadas.

Observações:
- Usa o bucket `animal-images`; requer utilizador autenticado para enviar.
- Implementa tentativas com pequeno retry em falha de upload.
*/
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  // Cliente Supabase e nome do bucket.
  final _client = Supabase.instance.client;
  final String bucket = 'animal-images';

  // Faz upload de um ficheiro para `destPath` e devolve URL pública.
  Future<String> uploadAnimalImage(File file, String destPath) async {
    // Garante que há utilizador autenticado.
    final current = _client.auth.currentUser;
    if (current == null) {
      throw Exception('Usuário não autenticado. Faça login antes de enviar imagens.');
    }

    // Lê bytes do ficheiro local.
    final bytes = await file.readAsBytes();
    // ignore: avoid_print
    print('StorageRepository: current user id=${current.id}');
    // Tenta duas vezes o upload, esperando 1s entre tentativas em caso de erro.
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await _client.storage.from(bucket).uploadBinary(destPath, bytes, fileOptions: FileOptions(cacheControl: '3600'));
        final url = _client.storage.from(bucket).getPublicUrl(destPath);
        return url;
      } catch (e, st) {
        // ignore: avoid_print
        print('StorageRepository.uploadAnimalImage attempt $attempt failed: $e');
        // ignore: avoid_print
        print(st);
        if (attempt == 2) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Upload failed');
  }

  // Cria um URL assinado (temporário) para um caminho do bucket.
  Future<String?> createSignedUrl(String path, {int expiresIn = 3600}) async {
    try {
      final signed = await _client.storage.from(bucket).createSignedUrl(path, expiresIn);
      return signed;
    } catch (e) {
      rethrow;
    }
  }
}
