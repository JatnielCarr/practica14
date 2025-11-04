import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class PuzzleCompletedWidget extends ConsumerWidget {
  const PuzzleCompletedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzle = ref.watch(puzzleProvider);
    final size = ref.watch(sizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('¡Puzzle Completado!'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration,
              size: 100,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Felicitaciones!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Has completado el crucigrama de ${size.width} x ${size.height}',
              style: const TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${puzzle.selectedWords.length} palabras colocadas',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // Reset puzzle and go back to generation
                ref.invalidate(puzzleProvider);
                ref.invalidate(workQueueProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Generar Nuevo Puzzle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Change size and generate new puzzle
                final newSize = size == CrosswordSize.small
                    ? CrosswordSize.medium
                    : size == CrosswordSize.medium
                        ? CrosswordSize.large
                        : CrosswordSize.small;
                ref.read(sizeProvider.notifier).setSize(newSize);
                ref.invalidate(puzzleProvider);
                ref.invalidate(workQueueProvider);
              },
              icon: const Icon(Icons.aspect_ratio),
              label: Text('Cambiar a ${size == CrosswordSize.small ? 'Mediano' : size == CrosswordSize.medium ? 'Grande' : 'Pequeño'}'),
            ),
          ],
        ),
      ),
    );
  }
}