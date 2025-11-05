import 'package:flutter/material.dart';
import '../supabase_service.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Global'),
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.instance.getRanking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          final ranking = snapshot.data ?? [];

          if (ranking.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay datos en el ranking aún',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '¡Sé el primero en completar todas las palabras exclusivas!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final entry = ranking[index];
              final isTopThree = index < 3;
              final medalColor = index == 0
                  ? Colors.amber
                  : index == 1
                      ? Colors.grey[400]
                      : Colors.brown[300];
              
              final tiempoMs = entry['tiempo_en_milisegundos'] as int;
              final duration = Duration(milliseconds: tiempoMs);
              final timeString = _formatTime(duration);

              return Card(
                elevation: isTopThree ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isTopThree ? medalColor : Colors.blueGrey,
                    child: isTopThree
                        ? Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(
                    entry['username'] as String,
                    style: TextStyle(
                      fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                      fontSize: isTopThree ? 18 : 16,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: isTopThree ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const Text(
                        'tiempo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else if (seconds > 0) {
      return '${seconds}.${(milliseconds / 100).floor()}s';
    } else {
      return '${milliseconds}ms';
    }
  }
}
