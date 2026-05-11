import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../core/theme.dart';
import '../models/camera_model.dart';

class FullscreenScreen extends StatefulWidget {
  const FullscreenScreen({super.key, required this.camera});
  final CameraModel camera;

  @override
  State<FullscreenScreen> createState() => _FullscreenScreenState();
}

class _FullscreenScreenState extends State<FullscreenScreen> {
  late VlcPlayerController _controller;
  bool _controlsVisible = true;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VlcPlayerController.network(
      widget.camera.buildRtspUrl(),
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
          '--rtsp-tcp',
        ]),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Full video
            Center(
              child: VlcPlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
                placeholder: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

            // Scanline overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ScanlinePainter(),
                ),
              ),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                children: [
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: AppTheme.textPrimary, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.camera.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontFamily: 'IBM Plex Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          // LIVE badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center play/pause
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.6)),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppTheme.accent,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  // Bottom info bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              color: AppTheme.success, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            widget.camera.lanIp,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'IBM Plex Mono',
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.camera.type.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontFamily: 'IBM Plex Mono',
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06FFFFFF)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
