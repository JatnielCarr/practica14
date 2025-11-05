import 'dart:convert';
// Drop the dart:math import

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'isolates.dart';
import 'model.dart' as model;
import 'supabase_service.dart';

part 'providers.g.dart';

// OPTIMIZACIÓN: Reducir workers para mejor rendimiento en móviles
const backgroundWorkerCount = 1; // Reducido a 1 para móviles (más estable)

/// Provider for exclusive words from Supabase (only when online)
@riverpod
Future<List<String>> exclusiveWords(Ref ref) async {
  try {
    final exclusiveWords = await SupabaseService.instance.getPalabrasExclusivas();
    if (exclusiveWords.isNotEmpty) {
      debugPrint('Loaded ${exclusiveWords.length} exclusive words from Supabase - ONLINE MODE');
    } else {
      debugPrint('No exclusive words loaded - OFFLINE MODE');
    }
    return exclusiveWords;
  } catch (e) {
    debugPrint('Error loading exclusive words (OFFLINE): $e');
    return []; // Return empty list if offline or error
  }
}

/// Provider to track if we have internet connection (based on exclusive words)
@riverpod
Future<bool> hasInternetConnection(Ref ref) async {
  final exclusiveWords = await ref.watch(exclusiveWordsProvider.future);
  return exclusiveWords.isNotEmpty;
}

/// A provider for the wordlist to use when generating the crossword.
@riverpod
Future<BuiltSet<String>> wordList(Ref ref) async {
  final re = RegExp(r'^[a-z]+$');
  final words = await rootBundle.loadString('assets/words.txt');
  final exclusiveWordsAsync = await ref.watch(exclusiveWordsProvider.future);
  
  final baseWords = const LineSplitter()
      .convert(words)
      .toBuiltSet()
      .rebuild(
        (b) => b
          ..map((word) => word.toLowerCase().trim())
          ..where((word) => word.length > 2)
          ..where((word) => re.hasMatch(word)),
      );
  
  // Only add exclusive words if we have internet connection
  if (exclusiveWordsAsync.isNotEmpty) {
    debugPrint('Adding ${exclusiveWordsAsync.length} exclusive words to crossword (ONLINE)');
    return baseWords.rebuild((b) => b.addAll(exclusiveWordsAsync.map((word) => word.toLowerCase())));
  } else {
    debugPrint('Generating crossword without exclusive words (OFFLINE)');
    return baseWords;
  }
}

enum CrosswordSize {
  small(width: 20, height: 11),
  medium(width: 30, height: 17),  // OPTIMIZACIÓN: Reducido para móviles (antes 40x22)
  large(width: 50, height: 28),   // OPTIMIZACIÓN: Reducido para móviles (antes 80x44)
  xlarge(width: 80, height: 44),  // OPTIMIZACIÓN: Reducido para móviles (antes 160x88)
  xxlarge(width: 120, height: 66); // OPTIMIZACIÓN: Reducido para móviles (antes 500x500)

  const CrosswordSize({required this.width, required this.height});

  final int width;
  final int height;
  String get label => '$width x $height';
}

@Riverpod(keepAlive: true)
class Size extends _$Size {
  var _size = CrosswordSize.medium;

  @override
  CrosswordSize build() => _size;

  void setSize(CrosswordSize size) {
    _size = size;
    ref.invalidateSelf();
  }
}

@riverpod
Stream<model.WorkQueue> workQueue(Ref ref) async* {
  final size = ref.watch(sizeProvider);                   // Drop the ref.watch(workerCountProvider)
  final wordListAsync = ref.watch(wordListProvider);
  final emptyCrossword = model.Crossword.crossword(
    width: size.width,
    height: size.height,
  );
  final emptyWorkQueue = model.WorkQueue.from(
    crossword: emptyCrossword,
    candidateWords: BuiltSet<String>(),
    startLocation: model.Location.at(0, 0),
  );
                                                          // Drop the startTimeProvider and endTimeProvider refs
  yield* wordListAsync.when(
    data: (wordList) => exploreCrosswordSolutions(
      crossword: emptyCrossword,
      wordList: wordList,
      maxWorkerCount: backgroundWorkerCount,              // Edit this line
    ),
    error: (error, stackTrace) async* {
      debugPrint('Error loading word list: $error');
      yield emptyWorkQueue;
    },
    loading: () async* {
      yield emptyWorkQueue;
    },
  );
}                                                         // Drop the endTimeProvider ref

@Riverpod(keepAlive: true)                                 // Add from here to end of file
class Puzzle extends _$Puzzle {
  model.CrosswordPuzzleGame _puzzle = model.CrosswordPuzzleGame.from(
    crossword: model.Crossword.crossword(width: 0, height: 0),
    candidateWords: BuiltSet<String>(),
  );

  @override
  model.CrosswordPuzzleGame build() {
    final size = ref.watch(sizeProvider);
    final wordList = ref.watch(wordListProvider).value;
    final workQueue = ref.watch(workQueueProvider).value;

    if (wordList != null &&
        workQueue != null &&
        workQueue.isCompleted &&
        (_puzzle.crossword.height != size.height ||
            _puzzle.crossword.width != size.width ||
            _puzzle.crossword != workQueue.crossword)) {
      compute(_puzzleFromCrosswordTrampoline, (
        workQueue.crossword,
        wordList,
      )).then((puzzle) {
        _puzzle = puzzle;
        ref.invalidateSelf();
      });
    }

    return _puzzle;
  }

  Future<void> selectWord({
    required model.Location location,
    required String word,
    required model.Direction direction,
  }) async {
    final candidate = await compute(_puzzleSelectWordTrampoline, (
      _puzzle,
      location,
      word,
      direction,
    ));

    if (candidate != null) {
      _puzzle = candidate;
      ref.invalidateSelf();
    } else {
      debugPrint('Invalid word selection: $word');
    }
  }

  bool canSelectWord({
    required model.Location location,
    required String word,
    required model.Direction direction,
  }) {
    return _puzzle.canSelectWord(
      location: location,
      word: word,
      direction: direction,
    );
  }
}

// Trampoline functions to disentangle these Isolate target calls from the
// unsendable reference to the [Puzzle] provider.

Future<model.CrosswordPuzzleGame> _puzzleFromCrosswordTrampoline(
  (model.Crossword, BuiltSet<String>) args,
) async =>
    model.CrosswordPuzzleGame.from(crossword: args.$1, candidateWords: args.$2);

model.CrosswordPuzzleGame? _puzzleSelectWordTrampoline(
  (model.CrosswordPuzzleGame, model.Location, String, model.Direction) args,
) => args.$1.selectWord(location: args.$2, word: args.$3, direction: args.$4);
