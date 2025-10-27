import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/animal.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  const AnimalCard({super.key, required this.animal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasMedia = animal.media.isNotEmpty;
    final isImage  = hasMedia ? animal.media.first.type == 'image' : false;
    final path     = hasMedia ? animal.media.first.path : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (hasMedia && isImage)
              Image.file(File(path!), width: 120, height: 120, fit: BoxFit.cover)
            else
              Container(
                width: 120, height: 120,
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.play_circle, size: 40),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animal.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${animal.tipo} • ${animal.tamanho} • ${animal.sexo}'),
                    Text('${animal.idadeMeses} meses • ${animal.pesoKg} kg'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
