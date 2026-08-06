import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'workout_screen.dart';
import 'workout_complete_screen.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutPlayerScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  YoutubePlayerController? _youtubeController;
  Timer? _timer;
  bool _isPlaying = true;
  int _elapsedSeconds = 0;
  int get _totalSeconds =>
      _youtubeController?.value.metaData.duration.inSeconds != 0
          ? (_youtubeController?.value.metaData.duration.inSeconds ?? widget.workout.duration * 60)
          : (widget.workout.duration * 60);

  @override
  void initState() {
    super.initState();
    if (widget.workout.videoId != null && widget.workout.videoId!.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: widget.workout.videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: true,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: false,
          hideControls: true,
          controlsVisibleAtStart: false,
          hideThumbnail: true,
        ),
      )..addListener(_onYoutubeStateChange);
    } else {
      _startTimer();
    }
  }

  void _onYoutubeStateChange() {
    if (_youtubeController == null || !mounted) return;
    setState(() {
      _isPlaying = _youtubeController!.value.isPlaying;
      _elapsedSeconds = _youtubeController!.value.position.inSeconds;
    });

    if (_youtubeController!.value.playerState == PlayerState.ended) {
      _showFinishedScreen();
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_onYoutubeStateChange);
    _youtubeController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;

      setState(() {
        if (_elapsedSeconds < _totalSeconds) {
          _elapsedSeconds++;
        } else {
          _timer?.cancel();
          _isPlaying = false;
          _showFinishedScreen();
        }
      });
    });
  }

  void _togglePlayPause() {
    if (_youtubeController != null) {
      if (_youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
      } else {
        _youtubeController!.play();
      }
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _nextTrack() {
    if (_youtubeController != null) {
      final current = _youtubeController!.value.position;
      _youtubeController!.seekTo(current + const Duration(seconds: 15));
    } else {
      setState(() {
        _elapsedSeconds = (_elapsedSeconds + 30).clamp(0, _totalSeconds);
      });
    }
  }

  void _previousTrack() {
    if (_youtubeController != null) {
      final current = _youtubeController!.value.position;
      _youtubeController!.seekTo(current - const Duration(seconds: 15));
    } else {
      setState(() {
        _elapsedSeconds = (_elapsedSeconds - 30).clamp(0, _totalSeconds);
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showFinishedScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutCompleteScreen(
          workout: widget.workout,
          duration: widget.workout.duration,
          calories: 140,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final remainingSeconds = _totalSeconds - _elapsedSeconds;
    final progress = _elapsedSeconds / _totalSeconds;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF3B2413),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF3B2413),
        body: Stack(
        children: [
          // 1. YouTube Video / Cover Image in upper portion
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.58,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _youtubeController != null
                      ? IgnorePointer(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.width * 9 / 16,
                                child: YoutubePlayer(
                                  controller: _youtubeController!,
                                  showVideoProgressIndicator: false,
                                  topActions: const [],
                                  bottomActions: const [],
                                ),
                              ),
                            ),
                          ),
                        )
                      : Image.asset(
                          widget.workout.imagePath,
                          fit: BoxFit.contain,
                        ),
                ),
                // Dark Gradient overlay blending downwards into player background
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                            const Color(0xFF3B2413).withValues(alpha: 0.8),
                            const Color(0xFF3B2413),
                          ],
                          stops: const [0.0, 0.4, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),


          // 2. Top Chevron Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.0,
            left: AppSpacing.l,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.wellnessBrown,
                  size: 28,
                ),
              ),
            ),
          ),

          // 3. Lower Half Content & Media Player Controls
          Positioned(
            left: AppSpacing.l,
            right: AppSpacing.l,
            bottom: MediaQuery.of(context).padding.bottom + 40.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // NOW PLAYING Subtitle
                Text(
                  'NOW PLAYING',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12.0,
                  ),
                ),
                const SizedBox(height: 6.0),

                // Workout Title
                Text(
                  widget.workout.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28.0,
                  ),
                ),
                const SizedBox(height: 20.0),

                // Timeline Progress Line
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.0),
                  child: SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEE8AA4)),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),

                // Elapsed Time & Remaining Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13.0,
                      ),
                    ),
                    Text(
                      '-${_formatDuration(remainingSeconds)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48.0),

                // Media Player Control Buttons Row (Prev, Play/Pause, Next)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Previous Track Button
                    GestureDetector(
                      onTap: _previousTrack,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: const Icon(
                          Icons.skip_previous_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24.0),

                    // Main Play / Pause Button (White Rounded Rectangle)
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFF3B2413),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24.0),

                    // Next Track Button
                    GestureDetector(
                      onTap: _nextTrack,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: const Icon(
                          Icons.skip_next_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
