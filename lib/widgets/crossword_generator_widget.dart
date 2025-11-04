import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'crossword_widget.dart';
import 'crossword_info_widget.dart';

class CrosswordGeneratorWidget extends ConsumerWidget {
  const CrosswordGeneratorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workQueueAsync = ref.watch(workQueueProvider);
    final size = ref.watch(sizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generando Crucigrama'),
        actions: [
          DropdownButton<CrosswordSize>(
            value: size,
            items: CrosswordSize.values.map((size) {
              return DropdownMenuItem(
                value: size,
                child: Text(size.label),
              );
            }).toList(),
            onChanged: (newSize) {
              if (newSize != null) {
                ref.read(sizeProvider.notifier).setSize(newSize);
              }
            },
          ),
        ],
      ),
      body: workQueueAsync.when(
        data: (workQueue) => Column(
          children: [
            const CrosswordInfoWidget(),
            Expanded(
              child: const CrosswordWidget(),
            ),
          ],
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}