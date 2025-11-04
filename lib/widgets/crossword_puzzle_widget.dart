import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart' as model;
import '../providers.dart';

class CrosswordPuzzleWidget extends ConsumerWidget {
  const CrosswordPuzzleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(sizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Crucigrama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reset puzzle
              ref.invalidate(puzzleProvider);
            },
          ),
        ],
      ),
      body: TableView.builder(
        diagonalDragBehavior: DiagonalDragBehavior.free,
        cellBuilder: _buildCell,
        columnCount: size.width,
        columnBuilder: (index) => _buildSpan(context, index),
        rowCount: size.height,
        rowBuilder: (index) => _buildSpan(context, index),
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final location = model.Location.at(vicinity.column, vicinity.row);

    return TableViewCell(
      child: Consumer(
        builder: (context, ref, _) {
          final puzzle = ref.watch(puzzleProvider);
          final character = puzzle.crossword.characters[location];

          if (character != null) {
            // Check if this location is part of a selected word
            final isSelected = puzzle.selectedWords.any((selectedWord) {
              final startLocation = selectedWord.location;
              final length = selectedWord.word.length;
              final direction = selectedWord.direction;

              for (int i = 0; i < length; i++) {
                final wordLocation = direction == model.Direction.across
                    ? startLocation.rightOffset(i)
                    : startLocation.downOffset(i);
                if (wordLocation == location) return true;
              }
              return false;
            });

            return InkWell(
              onTap: () => _showWordSelectionDialog(context, ref, location),
              child: AnimatedContainer(
                duration: Durations.medium1,
                curve: Curves.easeInOut,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: Durations.medium1,
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(character.character),
                  ),
                ),
              ),
            );
          }

          return ColoredBox(
            color: Theme.of(context).colorScheme.primaryContainer,
          );
        },
      ),
    );
  }

  void _showWordSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    model.Location location,
  ) {
    final puzzle = ref.read(puzzleProvider);

    // Find all possible words that can be placed at this location
    final possibleWords = <String>{};

    // Find the start location of the word at this position
    model.Location? acrossStartLocation;
    model.Location? downStartLocation;

    // Check if this location has an across word
    final character = puzzle.crossword.characters[location];
    if (character?.acrossWord != null) {
      acrossStartLocation = character!.acrossWord!.location;
    }

    // Check if this location has a down word
    if (character?.downWord != null) {
      downStartLocation = character!.downWord!.location;
    }

    // Check across direction alternatives
    if (acrossStartLocation != null) {
      final acrossAlternates = puzzle.alternateWords[acrossStartLocation]?[model.Direction.across];
      if (acrossAlternates != null) {
        possibleWords.addAll(acrossAlternates);
      }
      // Add original word
      final originalAcrossWord = puzzle.crossword.words.firstWhere(
        (word) => word.location == acrossStartLocation && word.direction == model.Direction.across,
      );
      possibleWords.add(originalAcrossWord.word);
    }

    // Check down direction alternatives
    if (downStartLocation != null) {
      final downAlternates = puzzle.alternateWords[downStartLocation]?[model.Direction.down];
      if (downAlternates != null) {
        possibleWords.addAll(downAlternates);
      }
      // Add original word
      final originalDownWord = puzzle.crossword.words.firstWhere(
        (word) => word.location == downStartLocation && word.direction == model.Direction.down,
      );
      possibleWords.add(originalDownWord.word);
    }

    if (possibleWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay palabras disponibles para esta posición')),
      );
      return;
    }

    final sortedWords = possibleWords.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Palabra'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedWords.length,
            itemBuilder: (context, index) {
              final word = sortedWords[index];
              return ListTile(
                title: Text(word),
                onTap: () {
                  Navigator.of(context).pop();
                  _trySelectWord(context, ref, location, word);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _trySelectWord(
    BuildContext context,
    WidgetRef ref,
    model.Location location,
    String word,
  ) async {
    final puzzle = ref.read(puzzleProvider);

    // Find the start location of the word at this position
    model.Location? acrossStartLocation;
    model.Location? downStartLocation;

    final character = puzzle.crossword.characters[location];
    if (character?.acrossWord != null) {
      acrossStartLocation = character!.acrossWord!.location;
    }
    if (character?.downWord != null) {
      downStartLocation = character!.downWord!.location;
    }

    // Try across first if we have an across word
    if (acrossStartLocation != null &&
        puzzle.canSelectWord(
          location: acrossStartLocation,
          word: word,
          direction: model.Direction.across,
        )) {
      await ref.read(puzzleProvider.notifier).selectWord(
        location: acrossStartLocation,
        word: word,
        direction: model.Direction.across,
      );
      return;
    }

    // Try down if we have a down word
    if (downStartLocation != null &&
        puzzle.canSelectWord(
          location: downStartLocation,
          word: word,
          direction: model.Direction.down,
        )) {
      await ref.read(puzzleProvider.notifier).selectWord(
        location: downStartLocation,
        word: word,
        direction: model.Direction.down,
      );
      return;
    }

    // Word cannot be selected
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se puede colocar "$word" en esta posición')),
    );
  }

  TableSpan _buildSpan(BuildContext context, int index) {
    return TableSpan(
      extent: FixedTableSpanExtent(32),
      foregroundDecoration: TableSpanDecoration(
        border: TableSpanBorder(
          leading: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          trailing: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}