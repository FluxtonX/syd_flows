import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/workout_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../profile/presentation/screens/subscription_screen.dart';
import '../../../../core/utils/helpers.dart';
import 'workout_screen.dart';
import 'workout_complete_screen.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutPlayerScreen({super.key, required this.workout});

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
  bool _hasVideoError = false;
  bool _hasSavedProgress = false;
  bool _isRestored = false;

  // Fix #4: Premium access guard — prevents video from starting before subscription check
  bool _isCheckingAccess = false;

  // Controls Auto-Hide State (Portrait & Landscape)
  bool _showControls = true;
  Timer? _controlsTimer;

  // Double-tap seek visual feedback states
  bool _showRewindIndicator = false;
  bool _showForwardIndicator = false;
  Timer? _seekIndicatorTimer;

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

  @override
  void initState() {
    super.initState();

    // Allow all orientations on this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Fix #4: For premium workouts, verify subscription BEFORE initializing video.
    // This eliminates the race condition where the video would start playing
    // concurrently with the async access check.
    if (widget.workout.isPaid) {
      setState(() => _isCheckingAccess = true);
      SubscriptionService.instance.streamHasPremiumAccess().first.then((
        hasAccess,
      ) {
        if (!mounted) return;
        if (!hasAccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        } else {
          // Access confirmed — now initialize video and controls
          setState(() => _isCheckingAccess = false);
          _initVideoControllers();
          _restoreSavedPosition();
          _startControlsTimer();
        }
      }).catchError((_) {
        // On error, deny access safely
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        }
      });
    } else {
      // Free workout — initialize immediately
      _initVideoControllers();
      _restoreSavedPosition();
      _startControlsTimer();
    }
  }

  /// Initializes the appropriate video controller based on workout data.
  void _initVideoControllers() {
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
        ..initialize()
            .then((_) {
              if (!mounted) return;
              setState(() {
                _isVideoInitialized = true;
                _hasVideoError = false;
              });
              _videoPlayerController!.play();
              _videoPlayerController!.setLooping(false);
              _restoreSavedPosition();
            })
            .catchError((error) {
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

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _toggleOrientation(bool isCurrentlyLandscape) {
    if (isCurrentlyLandscape) {
      // Exiting fullscreen — restore portrait and system UI
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    } else {
      // Fix #3: Entering fullscreen — force hide ALL system bars immediately
      // before orientation changes so bars never flash over the video.
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _restoreSavedPosition() async {
    if (_isRestored) return;
    final posKey = 'video_pos_${widget.workout.id}';
    final savedSeconds = await LocalStorageService.instance.getInt(posKey);
    if (savedSeconds != null &&
        savedSeconds > 5 &&
        savedSeconds < _totalSeconds - 10) {
      _isRestored = true;
      setState(() {
        _elapsedSeconds = savedSeconds;
      });

      if (_youtubeController != null) {
        _youtubeController!.seekTo(Duration(seconds: savedSeconds));
      } else if (_videoPlayerController != null && _isVideoInitialized) {
        _videoPlayerController!.seekTo(Duration(seconds: savedSeconds));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resumed workout from ${_formatDuration(savedSeconds)} ⏯️',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.wellnessBrown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveProgressAndExit() async {
    if (_hasSavedProgress) return;
    _hasSavedProgress = true;

    final posKey = 'video_pos_${widget.workout.id}';

    // 1. Save last position timestamp for resuming later
    if (_elapsedSeconds > 5 && _elapsedSeconds < _totalSeconds - 10) {
      await LocalStorageService.instance.saveInt(posKey, _elapsedSeconds);
      Helpers.log(
        'Saved video resume position: $_elapsedSeconds seconds for workout ${widget.workout.id}',
      );
    } else if (_elapsedSeconds >= _totalSeconds - 10) {
      await LocalStorageService.instance.remove(posKey);
    }

    // 2. Record partial minutes to Firestore workout_history for graph
    final user = AuthService.instance.currentUser;
    if (user != null && _elapsedSeconds >= 15) {
      final durationMins = (_elapsedSeconds / 60.0).ceil();
      final calories = ((durationMins / widget.workout.duration) * 140)
          .round()
          .clamp(10, 300);

      await WorkoutService.instance.logCompletedWorkout(
        uid: user.uid,
        workout: widget.workout,
        duration: durationMins,
        calories: calories,
      );

      Helpers.log(
        'Saved partial workout: $durationMins mins for user ${user.uid}',
      );
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
    // Reset orientations to portrait preference and restore system overlays
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controlsTimer?.cancel();
    _seekIndicatorTimer?.cancel();
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
    HapticFeedback.lightImpact();
    if (_youtubeController != null) {
      if (_youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
        setState(() {
          _isPlaying = false;
          _showControls = true;
        });
        _controlsTimer?.cancel();
      } else {
        _youtubeController!.play();
        setState(() => _isPlaying = true);
        _startControlsTimer();
      }
    } else if (_videoPlayerController != null && _isVideoInitialized) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        setState(() {
          _isPlaying = false;
          _showControls = true;
        });
        _controlsTimer?.cancel();
      } else {
        _videoPlayerController!.play();
        setState(() => _isPlaying = true);
        _startControlsTimer();
      }
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
        if (!_isPlaying) {
          _showControls = true;
          _controlsTimer?.cancel();
        } else {
          _startControlsTimer();
        }
      });
    }
  }

  void _seekTo(int seconds) {
    final clamped = seconds.clamp(0, _totalSeconds);
    setState(() {
      _elapsedSeconds = clamped;
    });
    if (_youtubeController != null) {
      _youtubeController!.seekTo(Duration(seconds: clamped));
    } else if (_videoPlayerController != null && _isVideoInitialized) {
      _videoPlayerController!.seekTo(Duration(seconds: clamped));
    }
    _startControlsTimer();
  }

  void _seekRelative(int deltaSeconds) {
    HapticFeedback.lightImpact();
    _seekTo(_elapsedSeconds + deltaSeconds);

    _seekIndicatorTimer?.cancel();
    setState(() {
      if (deltaSeconds < 0) {
        _showRewindIndicator = true;
        _showForwardIndicator = false;
      } else {
        _showForwardIndicator = true;
        _showRewindIndicator = false;
      }
    });

    _seekIndicatorTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showRewindIndicator = false;
          _showForwardIndicator = false;
        });
      }
    });
  }

  void _nextTrack() {
    _seekRelative(10);
  }

  void _previousTrack() {
    if (_elapsedSeconds > 3) {
      _seekRelative(-10);
    } else {
      HapticFeedback.lightImpact();
      _seekTo(0);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showFinishedScreen() async {
    _hasSavedProgress = true;
    final posKey = 'video_pos_${widget.workout.id}';
    await LocalStorageService.instance.remove(posKey);

    if (!mounted) return;
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

  Widget _buildVideoSurface(bool isLandscape) {
    if (_youtubeController != null && widget.workout.hasVideo) {
      return Center(
        child: FittedBox(
          fit: isLandscape ? BoxFit.contain : BoxFit.cover,
          child: SizedBox(
            width: isLandscape
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width,
            height: isLandscape
                ? MediaQuery.of(context).size.height
                : MediaQuery.of(context).size.width * 9 / 16,
            child: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: false,
              topActions: const [],
              bottomActions: const [],
            ),
          ),
        ),
      );
    }

    if (_videoPlayerController != null && _isVideoInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio > 0
              ? _videoPlayerController!.value.aspectRatio
              : 16 / 9,
          child: VideoPlayer(_videoPlayerController!),
        ),
      );
    }

    if (_videoPlayerController != null &&
        !_isVideoInitialized &&
        !_hasVideoError) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    return Container(
      color: const Color(0xFF23140A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            color: AppColors.white.withValues(alpha: 0.6),
            size: isLandscape ? 40.0 : 52.0,
          ),
          AppSpacing.h12,
          Text(
            'No Video Link Available',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'This workout does not have an attached video URL.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fix #4: Show loading screen while checking subscription access for paid workouts.
    if (_isCheckingAccess) {
      return Scaffold(
        backgroundColor: const Color(0xFF3B2413),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final remainingSeconds = (_totalSeconds - _elapsedSeconds).clamp(
      0,
      _totalSeconds,
    );
    final progress = _totalSeconds > 0
        ? (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _saveProgressAndExit();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          // Fix #3: In landscape, make both bars fully transparent/black
          // so they don't appear over the immersive video surface.
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: isLandscape ? Colors.black : const Color(0xFF3B2413),
          body: isLandscape
              ? _buildLandscapeView(progress, remainingSeconds)
              : _buildPortraitView(context, progress, remainingSeconds),
        ),
      ),
    );
  }

  /// ── Portrait View ───────────────────────────────────────────
  Widget _buildPortraitView(
    BuildContext context,
    double progress,
    int remainingSeconds,
  ) {
    return Stack(
      children: [
        // 1. Top Video Area with Gesture Overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.58,
          child: Stack(
            children: [
              Positioned.fill(child: _buildVideoSurface(false)),
              // Dark Gradient overlay blending downwards into player background
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
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
              // Gesture area: double tap left/right for 10s seek, single tap to toggle controls & play/pause
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () => _seekRelative(-10),
                        onTap: () {
                          if (!_showControls) {
                            setState(() => _showControls = true);
                            _startControlsTimer();
                          } else {
                            _togglePlayPause();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () => _seekRelative(10),
                        onTap: () {
                          if (!_showControls) {
                            setState(() => _showControls = true);
                            _startControlsTimer();
                          } else {
                            _togglePlayPause();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
              // Animated Double-Tap Seek Indicators
              if (_showRewindIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fast_rewind_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '-10s',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showForwardIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+10s',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.fast_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Top Bar (Back Button + Fullscreen Toggle - Auto Hiding)
        Positioned(
          top: MediaQuery.of(context).padding.top + 12.0,
          left: AppSpacing.l,
          right: AppSpacing.l,
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  _PlayerButton(
                    onTap: () async {
                      await _saveProgressAndExit();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
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

                  // Fullscreen Toggle Button
                  _PlayerButton(
                    onTap: () => _toggleOrientation(false),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(height: 12.0),

              // Interactive Timeline Slider (Matching Design Theme)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14.0,
                  ),
                  activeTrackColor: const Color(0xFFEE8AA4),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  thumbColor: const Color(0xFFEE8AA4),
                  overlayColor: const Color(0xFFEE8AA4).withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _elapsedSeconds.toDouble().clamp(
                    0.0,
                    _totalSeconds > 0 ? _totalSeconds.toDouble() : 1.0,
                  ),
                  min: 0.0,
                  max: _totalSeconds > 0 ? _totalSeconds.toDouble() : 1.0,
                  onChangeStart: (_) {
                    HapticFeedback.selectionClick();
                  },
                  onChanged: (value) {
                    setState(() {
                      _elapsedSeconds = value.toInt();
                    });
                  },
                  onChangeEnd: (value) {
                    HapticFeedback.selectionClick();
                    _seekTo(value.toInt());
                  },
                ),
              ),

              // Elapsed Time & Remaining Time Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
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
              ),
              const SizedBox(height: 36.0),

              // Media Player Control Buttons Row (Prev, Play/Pause, Next)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Previous Track / Rewind Button
                  _PlayerButton(
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

                  // Main Play / Pause Button
                  _PlayerButton(
                    onTap: _togglePlayPause,
                    scaleDown: 0.9,
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
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF3B2413),
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24.0),

                  // Next Track / Fast Forward Button
                  _PlayerButton(
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
    );
  }

  /// ── Landscape Fullscreen View ────────────────────────────────
  Widget _buildLandscapeView(double progress, int remainingSeconds) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControlsVisibility,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Video
          Center(child: _buildVideoSurface(true)),

          // 2. Auto-Hiding Controls Overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
                // Fix #3: Do NOT use SafeArea here — in immersiveSticky mode
                // there are no visible system bars, and SafeArea would add
                // incorrect padding that pushes controls away from the edges.
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Landscape Top Row
                        Row(
                          children: [
                            _PlayerButton(
                              onTap: () => _toggleOrientation(true),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                widget.workout.title,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _PlayerButton(
                              onTap: () => _toggleOrientation(true),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fullscreen_exit_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Landscape Center Controls Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rewind 10s
                            _PlayerButton(
                              onTap: _previousTrack,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.replay_10_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),

                            // Play / Pause Center Button
                            _PlayerButton(
                              onTap: _togglePlayPause,
                              scaleDown: 0.9,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFF3B2413),
                                  size: 38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),

                            // Forward 10s
                            _PlayerButton(
                              onTap: _nextTrack,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.forward_10_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Landscape Bottom Timeline & Duration Row
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12.0,
                                ),
                                activeTrackColor: const Color(0xFFEE8AA4),
                                inactiveTrackColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                                thumbColor: const Color(0xFFEE8AA4),
                              ),
                              child: Slider(
                                value: _elapsedSeconds.toDouble().clamp(
                                  0.0,
                                  _totalSeconds.toDouble(),
                                ),
                                min: 0.0,
                                max: _totalSeconds > 0
                                    ? _totalSeconds.toDouble()
                                    : 1.0,
                                onChangeStart: (_) {
                                  HapticFeedback.selectionClick();
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _elapsedSeconds = value.toInt();
                                  });
                                },
                                onChangeEnd: (value) {
                                  HapticFeedback.selectionClick();
                                  _seekTo(value.toInt());
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_elapsedSeconds),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_totalSeconds),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

/// Helper widget providing tactile press animation and haptic feedback to player buttons
class _PlayerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;

  const _PlayerButton({
    required this.child,
    required this.onTap,
    this.scaleDown = 0.92,
  });

  @override
  State<_PlayerButton> createState() => _PlayerButtonState();
}

class _PlayerButtonState extends State<_PlayerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
