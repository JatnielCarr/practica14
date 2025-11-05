import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'utils.dart';

Stream<WorkQueue> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
  required int maxWorkerCount,
}) async* {
  final start = DateTime.now();
  var workQueue = WorkQueue.from(
    crossword: crossword,
    candidateWords: wordList,
    startLocation: Location.at(0, 0),
  );
  while (!workQueue.isCompleted) {
    try {
      workQueue = await compute(_generate, (workQueue, maxWorkerCount));
      yield workQueue;
    } catch (e) {
      debugPrint('Error running isolate: $e');
    }
  }

  debugPrint(
    'Generated ${workQueue.crossword.width} x '
    '${workQueue.crossword.height} crossword in '
    '${DateTime.now().difference(start).formatted} '
    'with $maxWorkerCount workers.',
  );
}

Future<WorkQueue> _generate((WorkQueue, int) workMessage) async {
  var (workQueue, maxWorkerCount) = workMessage;
  final candidateGeneratorFutures = <Future<(Location, Direction, String?)>>[];
  final locations = workQueue.locationsToTry.keys.toBuiltList().rebuild(
    (b) => b
      ..shuffle()
      ..take(maxWorkerCount),
  );

  for (final location in locations) {
    final direction = workQueue.locationsToTry[location]!;

    candidateGeneratorFutures.add(
      compute(_generateCandidate, (
        workQueue.crossword,
        workQueue.candidateWords,
        location,
        direction,
      )),
    );
  }

  try {
    final results = await candidateGeneratorFutures.wait;
    var crossword = workQueue.crossword;
    for (final (location, direction, word) in results) {
      if (word != null) {
        final candidate = crossword.addWord(
          location: location,
          word: word,
          direction: direction,
        );
        if (candidate != null) {
          crossword = candidate;
        }
      } else {
        workQueue = workQueue.remove(location);
      }
    }

    workQueue = workQueue.updateFrom(crossword);
  } catch (e) {
    debugPrint('$e');
  }

  return workQueue;
}

(Location, Direction, String?) _generateCandidate(
  (Crossword, BuiltSet<String>, Location, Direction) searchDetailMessage,
) {
  final (crossword, candidateWords, location, direction) = searchDetailMessage;

  final target = crossword.characters[location];
  if (target == null) {
    return (location, direction, candidateWords.randomElement());
  }

  // OPTIMIZACIÓN: Crear lista una sola vez y limitar intentos
  final targetChar = target.character;
  final wordsList = candidateWords.where((word) => word.contains(targetChar)).toList()..shuffle();
  
  // OPTIMIZACIÓN: Reducir límites para mejor rendimiento en móviles
  const maxTries = 500; // Reducido de 1000
  const maxDuration = Duration(seconds: 5); // Reducido de 10
  
  int tryCount = 0;
  final start = DateTime.now();
  
  for (final word in wordsList) {
    if (tryCount >= maxTries || DateTime.now().difference(start) > maxDuration) {
      return (location, direction, null);
    }
    
    tryCount++;
    final wordChars = word.characters;
    
    for (int index = 0; index < wordChars.length; index++) {
      if (wordChars.elementAt(index) != targetChar) continue;

      final newLocation = switch (direction) {
        Direction.across => location.leftOffset(index),
        Direction.down => location.upOffset(index),
      };

      final candidate = crossword.addWord(
        location: newLocation,
        word: word,
        direction: direction,
      );
      
      if (candidate != null) {
        return (newLocation, direction, word);
      }
    }
  }

  return (location, direction, null);
}