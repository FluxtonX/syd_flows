class Workout {
  final String id;
  final String title;
  final String category;
  final int duration;
  final String difficulty;
  final String cyclePhase;
  final String type;
  final String equipment;
  final String propsUsed;
  final bool isPaid;
  final bool isFree;
  final String imagePath;
  final String? videoUrl;
  final String? videoId;

  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.difficulty,
    this.cyclePhase = 'Follicular Phase',
    required this.type,
    required this.equipment,
    this.propsUsed = 'Mat',
    this.isPaid = false,
    this.isFree = true,
    required this.imagePath,
    this.videoUrl,
    this.videoId,
  });

  bool get hasVideo =>
      (videoUrl != null && videoUrl!.isNotEmpty) ||
      (videoId != null && videoId!.isNotEmpty);

  factory Workout.fromFirestore(Map<String, dynamic> map, String docId) {
    int parsedDuration = 10;
    if (map['duration'] != null) {
      final durStr = map['duration'].toString();
      if (durStr.contains(':')) {
        final parts = durStr.split(':');
        if (parts.length == 2) {
          final mins = int.tryParse(parts[0]) ?? 0;
          final secs = int.tryParse(parts[1]) ?? 0;
          parsedDuration = mins > 0 ? mins : (secs > 0 ? 1 : 10);
        } else if (parts.length == 3) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final mins = int.tryParse(parts[1]) ?? 0;
          parsedDuration = (hours * 60) + mins;
        }
      } else {
        final match = RegExp(r'\d+').firstMatch(durStr);
        if (match != null) {
          parsedDuration = int.tryParse(match.group(0)!) ?? 10;
        }
      }
    }

    final String? vUrl = (map['videoUrl'] as String?)?.isNotEmpty == true
        ? map['videoUrl'] as String
        : ((map['youtubeUrl'] as String?)?.isNotEmpty == true ? map['youtubeUrl'] as String : null);

    final String videoSource = (map['videoSource'] ?? '').toString().toLowerCase();
    String? vId;

    if (vUrl != null && vUrl.isNotEmpty) {
      final youtubeRegExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
        caseSensitive: false,
      );
      final match = youtubeRegExp.firstMatch(vUrl);
      if (match != null && match.group(1) != null) {
        vId = match.group(1);
      }
    } else if (videoSource == 'youtube' && (map['youtubeId'] as String?)?.isNotEmpty == true) {
      vId = map['youtubeId'] as String;
    }

    final cat = (map['category'] ?? 'Yoga').toString();

    return Workout(
      id: docId,
      title: map['title'] ?? '',
      category: cat.toUpperCase(),
      duration: parsedDuration,
      difficulty: map['difficulty'] ?? 'Gentle',
      cyclePhase: map['cyclePhase'] ?? 'Follicular Phase',
      type: cat,
      equipment: map['propsUsed'] ?? map['equipment'] ?? 'Mat',
      propsUsed: map['propsUsed'] ?? map['equipment'] ?? 'Mat',
      isPaid: map['isPaid'] ?? (map['premium'] ?? false),
      isFree: map['isFree'] ?? (!(map['premium'] ?? false)),
      imagePath: map['thumbnailUrl'] ?? '',
      videoUrl: vUrl,
      videoId: vId,
    );
  }
}
