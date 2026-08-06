import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  Timer? _timer;
  bool _isPlaying = true;
  int _elapsedSeconds = 0;

  int get _totalSeconds {
    if (_youtubeController != null &&
        _youtubeController!.value.metaData.duration.inSeconds != 0) {
      return _youtubeController!.value.metaData.duration.inSeconds;
    }
    if (_videoPlayerController != null &&
        _isVideoInitialized &&
        _videoPlayerController!.value.duration.inSeconds != 0) {
      return _videoPlayerController!.value.duration.inSeconds;
    }
    return widget.workout.duration * 60;
  }

  bool _hasVideoError = false;

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
    } else if (widget.workout.videoUrl != null &&
        widget.workout.videoUrl!.isNotEmpty) {
      final Uri videoUri = Uri.parse(widget.workout.videoUrl!);
      _videoPlayerController = VideoPlayerController.networkUrl(videoUri)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isVideoInitialized = true;
            _hasVideoError = false;
          });
          _videoPlayerController!.play();
          _videoPlayerController!.setLooping(false);
        }).catchError((error) {
          if (!mounted) return;
          setState(() {
            _hasVideoError = true;
          });
          _startTimer();
        });
      _videoPlayerController!.addListener(_onVideoPlayerStateChange);
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

  void _onVideoPlayerStateChange() {
    if (_videoPlayerController == null || !mounted || !_isVideoInitialized) {
      return;
    }
    final value = _videoPlayerController!.value;
    setState(() {
      _isPlaying = value.isPlaying;
      _elapsedSeconds = value.position.inSeconds;
    });

    if (value.position >= value.duration && value.duration.inSeconds > 0) {
      _showFinishedScreen();
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_onYoutubeStateChange);
    _youtubeController?.dispose();
    _videoPlayerController?.removeListener(_onVideoPlayerStateChange);
    _videoPlayerController?.dispose();
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
    } else if (_videoPlayerController != null && _isVideoInitialized) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
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
    } else if (_videoPlayerController != null && _isVideoInitialized) {
      final current = _videoPlayerController!.value.position;
      _videoPlayerController!.seekTo(current + const Duration(seconds: 15));
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
    } else if (_videoPlayerController != null && _isVideoInitialized) {
      final current = _videoPlayerController!.value.position;
      _videoPlayerController!.seekTo(current - const Duration(seconds: 15));
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
    final progress = _totalSeconds > 0 ? _elapsedSeconds / _totalSeconds : 0.0;

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
            // 1. YouTube Video / Custom MP4 Video Player / Fallback Cover
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.58,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: (_youtubeController != null && widget.workout.hasVideo)
                        ? IgnorePointer(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.width * 9 / 16,
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
                        : (_videoPlayerController != null && _isVideoInitialized)
                            ? Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoPlayerController!.value.aspectRatio > 0
                                          ? _videoPlayerController!.value.aspectRatio
                                          : 16 / 9,
                                  child: VideoPlayer(_videoPlayerController!),
                                ),
                              )
                            : (_videoPlayerController != null &&
                                    !_isVideoInitialized &&
                                    !_hasVideoError)
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF23140A),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.videocam_off_rounded,
                                          color: AppColors.white
                                              .withValues(alpha: 0.6),
                                          size: 52.0,
                                        ),
                                        AppSpacing.h12,
                                        Text(
                                          'No Video Link Available',
                                          style:
                                              AppTextStyles.titleMedium.copyWith(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          'This workout does not have an attached video URL.',
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.white
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
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
