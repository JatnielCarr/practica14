import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart' as model;
import '../providers.dart';
import '../supabase_service.dart';
import 'ranking_screen.dart';

class CrosswordPuzzleWidget extends ConsumerStatefulWidget {
  const CrosswordPuzzleWidget({super.key});

  @override
  ConsumerState<CrosswordPuzzleWidget> createState() => _CrosswordPuzzleWidgetState();
}

class _CrosswordPuzzleWidgetState extends ConsumerState<CrosswordPuzzleWidget> {
  String? userId;
  String? username;
  bool hasCompletedExclusiveWords = false;
  DateTime? startTime;
  bool isOnline = false;
  bool _hasInitialized = false; // Bandera para evitar inicialización múltiple

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeGame();
    }
  }

  Future<void> _initializeGame() async {
    // Check if we have internet connection
    final exclusiveWords = await SupabaseService.instance.getPalabrasExclusivas();
    final online = exclusiveWords.isNotEmpty;
    
    if (!mounted) return; // Verificar que el widget esté montado
    
    setState(() {
      isOnline = online;
    });

    if (online && mounted) {
      // Ask for username before starting
      final user = await _showInitialLoginDialog();
      if (user != null && mounted) {
        final uid = await SupabaseService.instance.loginOrCreateUser(user);
        if (uid != null && mounted) {
          setState(() {
            userId = uid;
            username = user;
            startTime = DateTime.now(); // Start timer
          });
        }
      }
    }
  }

  Future<String?> _showInitialLoginDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Modo Online!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Se detectaron palabras exclusivas.\nIngresa tu nombre para competir en el ranking.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Tu nombre de usuario',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Jugar sin registro'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  void _checkExclusiveWordsCompletion() {
    // OPTIMIZACIÓN: Usar addPostFrameCallback solo cuando sea necesario
    final puzzle = ref.read(puzzleProvider);
    final exclusiveWordsAsync = ref.read(exclusiveWordsProvider);

    exclusiveWordsAsync.whenData((exclusiveWords) {
      if (exclusiveWords.isEmpty || hasCompletedExclusiveWords) return;

      // Check if all exclusive words are in selectedWords
      final selectedWordStrings = puzzle.selectedWords.map((w) => w.word.toLowerCase()).toSet();
      final allFound = exclusiveWords.every((word) => selectedWordStrings.contains(word.toLowerCase()));

      if (allFound) {
        // Usar microtask para evitar setState durante build
        Future.microtask(() {
          if (mounted && !hasCompletedExclusiveWords) {
            setState(() {
              hasCompletedExclusiveWords = true;
            });
            _onExclusiveWordsCompleted();
          }
        });
      }
    });
  }

  void _onExclusiveWordsCompleted() {
    if (userId == null || startTime == null) {
      // User didn't register, just show congratulations
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Felicitaciones! Has encontrado todas las palabras exclusivas.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Calculate time taken
    final endTime = DateTime.now();
    final timeTaken = endTime.difference(startTime!);
    final milisegundos = timeTaken.inMilliseconds;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicitaciones! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '¡Has encontrado todas las palabras exclusivas!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tiempo: ${_formatTime(timeTaken)}',
              style: const TextStyle(fontSize: 24, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Usuario: $username',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // Register time in ranking
              await SupabaseService.instance.registrarTiempo(userId!, milisegundos);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Tiempo registrado en el ranking!')),
                );
                // Show ranking
                _showRanking();
              }
            },
            child: const Text('Ver Ranking'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${minutes}m ${seconds}s ${milliseconds}ms';
  }

  // OPTIMIZACIÓN: Formato simplificado para el temporizador en vivo (sin ms)
  String _formatTimeSimple(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = ref.watch(sizeProvider);
    final exclusiveWordsAsync = ref.watch(exclusiveWordsProvider);

    // Re-check completion when puzzle changes
    ref.listen(puzzleProvider, (previous, next) {
      _checkExclusiveWordsCompletion();
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resolver Crucigrama'),
            if (isOnline && startTime != null && username != null)
              Text(
                'Jugador: $username',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (isOnline)
            IconButton(
              icon: const Icon(Icons.leaderboard),
              onPressed: _showRanking,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reset puzzle
              ref.invalidate(puzzleProvider);
              setState(() {
                hasCompletedExclusiveWords = false;
                startTime = DateTime.now(); // Restart timer
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Online status and timer
          if (isOnline) ...[
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Modo Online', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (startTime != null && !hasCompletedExclusiveWords) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.timer, size: 20),
                    const SizedBox(width: 4),
                    // OPTIMIZACIÓN: Actualizar cada segundo en lugar de cada 100ms
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        if (startTime == null) return const Text('--:--');
                        final elapsed = DateTime.now().difference(startTime!);
                        return Text(
                          _formatTimeSimple(elapsed),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Exclusive words progress indicator
          exclusiveWordsAsync.when(
            data: (exclusiveWords) {
              if (exclusiveWords.isEmpty) return const SizedBox.shrink();
              
              final puzzle = ref.watch(puzzleProvider);
              final selectedWordStrings = puzzle.selectedWords.map((w) => w.word.toLowerCase()).toSet();
              final foundCount = exclusiveWords.where((word) => selectedWordStrings.contains(word.toLowerCase())).length;

              return Container(
                padding: const EdgeInsets.all(8),
                color: hasCompletedExclusiveWords 
                  ? Colors.green.shade100 
                  : Theme.of(context).colorScheme.secondaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Palabras exclusivas: $foundCount/${exclusiveWords.length}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (hasCompletedExclusiveWords) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Crossword grid
          Expanded(
            child: TableView.builder(
              diagonalDragBehavior: DiagonalDragBehavior.free,
              cellBuilder: _buildCell,
              columnCount: size.width,
              columnBuilder: (index) => _buildSpan(context, index),
              rowCount: size.height,
              rowBuilder: (index) => _buildSpan(context, index),
            ),
          ),
        ],
      ),
    );
  }

  void _showRanking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RankingScreen(),
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
                      fontSize: 18, // OPTIMIZACIÓN: Reducido de 24 para móviles
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    // CRUCIAL: Solo mostrar letra si está en palabra seleccionada
                    child: Text(isSelected ? character.character : ''),
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
        title: Text('Seleccionar Palabra (${sortedWords.length} opciones)'),
        content: SizedBox(
          width: double.maxFinite,
          height: sortedWords.length > 5 ? 300 : null,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedWords.length,
            itemBuilder: (context, index) {
              final word = sortedWords[index];
              // Verificar si la palabra ya está seleccionada
              final isAlreadySelected = puzzle.selectedWords.any((w) => w.word == word);
              
              return ListTile(
                leading: isAlreadySelected 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.radio_button_unchecked),
                title: Text(
                  word.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAlreadySelected ? Colors.green : null,
                  ),
                ),
                subtitle: Text('${word.length} letras'),
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
  }  void _trySelectWord(
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

    bool wordWasSelected = false;

    // Try across first if we have an across word
    if (acrossStartLocation != null) {
      // Verificar si la palabra es correcta antes de intentar seleccionarla
      final isCorrect = puzzle.crossword.words.any((w) => 
        w.location == acrossStartLocation && 
        w.direction == model.Direction.across && 
        w.word == word
      ) || (puzzle.alternateWords[acrossStartLocation]?[model.Direction.across]?.contains(word) == true);
      
      if (isCorrect) {
        await ref.read(puzzleProvider.notifier).selectWord(
          location: acrossStartLocation,
          word: word,
          direction: model.Direction.across,
        );
        wordWasSelected = true;
      }
    }

    // Try down if we have a down word and word wasn't selected yet
    if (!wordWasSelected && downStartLocation != null) {
      // Verificar si la palabra es correcta antes de intentar seleccionarla
      final isCorrect = puzzle.crossword.words.any((w) => 
        w.location == downStartLocation && 
        w.direction == model.Direction.down && 
        w.word == word
      ) || (puzzle.alternateWords[downStartLocation]?[model.Direction.down]?.contains(word) == true);
      
      if (isCorrect) {
        await ref.read(puzzleProvider.notifier).selectWord(
          location: downStartLocation,
          word: word,
          direction: model.Direction.down,
        );
        wordWasSelected = true;
      }
    }

    // Si no se seleccionó la palabra, es incorrecta
    if (!wordWasSelected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ "$word" no es la palabra correcta'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  TableSpan _buildSpan(BuildContext context, int index) {
    // OPTIMIZACIÓN: Tamaño de celda adaptativo para mejor rendimiento en móviles
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = screenWidth < 600 ? 28.0 : 32.0; // Más pequeño en móviles
    
    return TableSpan(
      extent: FixedTableSpanExtent(cellSize),
      foregroundDecoration: TableSpanDecoration(
        border: TableSpanBorder(
          leading: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            width: 0.5, // OPTIMIZACIÓN: Borde más delgado
          ),
          trailing: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            width: 0.5, // OPTIMIZACIÓN: Borde más delgado
          ),
        ),
      ),
    );
  }
}