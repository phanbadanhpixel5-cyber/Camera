import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../core/theme.dart';
import '../models/camera_model.dart';
import '../providers/camera_provider.dart';
import '../screens/fullscreen_screen.dart';

class CameraTile extends ConsumerStatefulWidget {
  const CameraTile({
    super.key,
    required this.camera,
    this.showControls = true,
  });

  final CameraModel camera;
  final bool showControls;

  @override
  ConsumerState<CameraTile> createState() => _CameraTileState();
}

class _CameraTileState extends ConsumerState<CameraTile> {
  late VlcPlayerController _controller;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;
  static const Duration reconnectDelay = Duration(seconds: 5);

  bool _useLan = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final url = widget.camera.buildRtspUrl(useLan: _useLan);
    _setStatus(ConnectionStatus.connecting);

    _controller = VlcPlayerController.network(
      url,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
          '--rtsp-tcp',
        ]),
        video: VlcVideoOptions([
          VlcVideoOptions.dropLateFrames(true),
          VlcVideoOptions.skipFrames(true),
        ]),
      ),
    );

    _controller.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (!mounted) return;
    final state = _controller.value.playingState;

    if (state == PlayingState.playing) {
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _setStatus(ConnectionStatus.connected);
    } else if (state == PlayingState.error || state == PlayingState.stopped) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _setStatus(ConnectionStatus.error);
      return;
    }
    _setStatus(ConnectionStatus.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      if (!mounted) return;
      _reconnectAttempts++;
      // Thử đổi sang WAN nếu LAN thất bại 3 lần
      if (_reconnectAttempts == 3 &&
          (widget.camera.wanIp != null || widget.camera.domain != null)) {
        _useLan = false;
      }
      final url = widget.camera.buildRtspUrl(useLan: _useLan);
      await _controller.setMediaFromNetwork(url, autoPlay: true);
    });
  }

  void _setStatus(ConnectionStatus s) {
    ref
        .read(cameraConnectionProvider.notifier)
        .setStatus(widget.camera.id, s);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenScreen(camera: widget.camera),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(cameraConnectionProvider)[widget.camera.id] ??
        ConnectionStatus.connecting;

    return GestureDetector(
      onDoubleTap: _openFullscreen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: _borderColor(status),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Video
            VlcPlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
              placeholder: const _LoadingPlaceholder(),
            ),

            // Scanline overlay (CCTV feel)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),

            // Top bar: camera name + status
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(camera: widget.camera, status: status),
            ),

            // Bottom bar: controls
            if (widget.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomBar(
                  onFullscreen: _openFullscreen,
                  onRemove: () => ref
                      .read(activeCamerasProvider.notifier)
                      .remove(widget.camera.id),
                  onReconnect: () {
                    _reconnectAttempts = 0;
                    _useLan = true;
                    _scheduleReconnect();
                  },
                ),
              ),

            // Reconnect overlay
            if (status == ConnectionStatus.reconnecting ||
                status == ConnectionStatus.error)
              Positioned.fill(
                child: _StatusOverlay(status: status, attempts: _reconnectAttempts),
              ),
          ],
        ),
      ),
    );
  }

  Color _borderColor(ConnectionStatus s) => switch (s) {
        ConnectionStatus.connected => AppTheme.accent.withOpacity(0.4),
        ConnectionStatus.error => AppTheme.danger.withOpacity(0.6),
        ConnectionStatus.reconnecting => AppTheme.warning.withOpacity(0.4),
        _ => AppTheme.border,
      };
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.camera, required this.status});
  final CameraModel camera;
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(status),
              boxShadow: status == ConnectionStatus.connected
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.6),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              camera.name.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                fontFamily: 'IBM Plex Mono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Timestamp
          Text(
            _timeString(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontFamily: 'IBM Plex Mono',
            ),
          ),
        ],
      ),
    );
  }

  String _timeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  Color _statusColor(ConnectionStatus s) => switch (s) {
        ConnectionStatus.connected => AppTheme.success,
        ConnectionStatus.error => AppTheme.danger,
        ConnectionStatus.reconnecting => AppTheme.warning,
        _ => AppTheme.textMuted,
      };
}

// ─── Bottom Bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onFullscreen,
    required this.onRemove,
    required this.onReconnect,
  });

  final VoidCallback onFullscreen;
  final VoidCallback onRemove;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _IconBtn(icon: Icons.refresh, onTap: onReconnect, tooltip: 'Reconnect'),
          _IconBtn(icon: Icons.fullscreen, onTap: onFullscreen, tooltip: 'Fullscreen'),
          _IconBtn(icon: Icons.close, onTap: onRemove, tooltip: 'Remove', color: AppTheme.danger),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppTheme.textSecondary,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Status Overlay ──────────────────────────────────────────────────────────

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.status, required this.attempts});
  final ConnectionStatus status;
  final int attempts;

  @override
  Widget build(BuildContext context) {
    final isError = status == ConnectionStatus.error;
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.videocam_off : Icons.refresh,
              color: isError ? AppTheme.danger : AppTheme.warning,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              isError
                  ? 'CONNECTION FAILED'
                  : 'RECONNECTING... ($attempts)',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 1.5,
                fontFamily: 'IBM Plex Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading Placeholder ─────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}

// ─── Scanline Painter ─────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.scanline
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
