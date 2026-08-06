class Workout {
  final String id;
  final String title;
  final String category;
  final int duration;
  final String difficulty;
  final String type;
  final String equipment;
  final String imagePath;
  final String? videoUrl;
  final String? videoId;

  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.type,
    required this.equipment,
    required this.imagePath,
    this.videoUrl,
    this.videoId,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty && videoId != null && videoId!.isNotEmpty;
}
