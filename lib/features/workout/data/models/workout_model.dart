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

  // Fields synced from admin panel
  final String trainer;
  final String description;
  final List<String> benefits;
  final List<String> symptoms;
  final List<String> recommendedPhases;
  final List<String> equipmentList;

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
    this.trainer = '',
    this.description = '',
    this.benefits = const [],
    this.symptoms = const [],
    this.recommendedPhases = const [],
    this.equipmentList = const [],
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
        : ((map['youtubeUrl'] as String?)?.isNotEmpty == true
              ? map['youtubeUrl'] as String
              : null);

    final String videoSource = (map['videoSource'] ?? '')
        .toString()
        .toLowerCase();
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
    } else if (videoSource == 'youtube' &&
        (map['youtubeId'] as String?)?.isNotEmpty == true) {
      vId = map['youtubeId'] as String;
    }

    final cat = (map['category'] ?? 'Yoga').toString();

    String thumb = (map['thumbnailUrl'] as String?)?.isNotEmpty == true
        ? map['thumbnailUrl'] as String
        : ((map['imagePath'] as String?)?.isNotEmpty == true
              ? map['imagePath'] as String
              : '');

    if (thumb.isEmpty && vId != null && vId.isNotEmpty) {
      thumb = 'https://img.youtube.com/vi/$vId/hqdefault.jpg';
    }

    // `isPaid` is canonical. `premium` is retained for older admin uploads.
    // Treat either true value as premium so an inconsistent legacy document
    // can never accidentally unlock a paid video.
    final isPaid = map['isPaid'] == true || map['premium'] == true;

    // Parse propsUsed — support both legacy string and new List<String>
    final rawProps = map['propsUsed'] ?? map['equipment'];
    String propsString;
    List<String> propsList;
    if (rawProps is List) {
      propsList = rawProps.map((e) => e.toString()).toList();
      propsString = propsList.join(', ');
    } else {
      propsString = rawProps?.toString() ?? 'Mat';
      propsList = propsString.isNotEmpty ? [propsString] : ['Mat'];
    }

    // Parse benefits — admin stores as List<String>
    final List<String> benefits = (map['benefits'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // Parse symptoms (symptomFriendly) — admin stores as List<String>
    final List<String> symptoms =
        (map['symptoms'] as List<dynamic>? ??
                map['symptomFriendly'] as List<dynamic>? ??
                [])
            .map((e) => e.toString())
            .toList();

    // Parse recommendedPhases — admin stores as List<String>
    // Also keep single cyclePhase string for backward compatibility
    final List<String> recommendedPhases =
        (map['recommendedPhases'] as List<dynamic>? ??
                map['phases'] as List<dynamic>? ??
                [])
            .map((e) => e.toString())
            .toList();

    final String cyclePhaseStr = recommendedPhases.isNotEmpty
        ? recommendedPhases.first
        : (map['cyclePhase']?.toString() ?? 'Follicular Phase');

    return Workout(
      id: docId,
      title: map['title'] ?? '',
      category: cat.toUpperCase(),
      duration: parsedDuration,
      difficulty: map['difficulty'] ?? 'Gentle',
      cyclePhase: cyclePhaseStr,
      type: cat,
      equipment: propsString,
      propsUsed: propsString,
      isPaid: isPaid,
      isFree: !isPaid,
      imagePath: thumb,
      videoUrl: vUrl,
      videoId: vId,
      trainer: map['trainer']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      benefits: benefits,
      symptoms: symptoms,
      recommendedPhases: recommendedPhases,
      equipmentList: propsList,
    );
  }
}
