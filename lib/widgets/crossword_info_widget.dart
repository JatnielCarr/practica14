import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class CrosswordInfoWidget extends ConsumerWidget {
  const CrosswordInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(sizeProvider);
    final workQueueAsync = ref.watch(workQueueProvider);

    return workQueueAsync.when(
      data: (workQueue) {
        final gridFilled = (workQueue.crossword.characters.length /
            (workQueue.crossword.width * workQueue.crossword.height));

        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 32.0, bottom: 32.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.onPrimary.withAlpha(230),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CrosswordInfoRichText(
                          label: 'Tamaño de cuadrícula',
                          value: '${size.width} x ${size.height}',
                        ),
                        _CrosswordInfoRichText(
                          label: 'Palabras en cuadrícula',
                          value: workQueue.crossword.words.length.toString(),
                        ),
                        _CrosswordInfoRichText(
                          label: 'Palabras candidatas',
                          value: workQueue.candidateWords.length.toString(),
                        ),
                        _CrosswordInfoRichText(
                          label: 'Ubicaciones por explorar',
                          value: workQueue.locationsToTry.length.toString(),
                        ),
                        _CrosswordInfoRichText(
                          label: 'Ubicaciones malas conocidas',
                          value: workQueue.badLocations.length.toString(),
                        ),
                        _CrosswordInfoRichText(
                          label: 'Cuadrícula llena',
                          value: '${(gridFilled * 100).toStringAsFixed(1)}%',
                        ),
                        _CrosswordInfoRichText(
                          label: 'Estado',
                          value: workQueue.isCompleted ? 'Completado' : 'Generando...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _CrosswordInfoRichText extends StatelessWidget {
  const _CrosswordInfoRichText({
    required this.label,
    required this.value,
  });

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(
            text: value.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
