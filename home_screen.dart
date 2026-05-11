import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/theme.dart';
import '../models/camera_model.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_grid.dart';
import 'add_camera_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCams = ref.watch(activeCamerasProvider);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 8),
            const Text('IP CAMERA VIEWER'),
          ],
        ),
        actions: [
          // Active count badge
          if (activeCams.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.accentDim,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${activeCams.length}/4',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontFamily: 'IBM Plex Mono',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Thêm camera',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCameraScreen()),
            ),
          ),
        ],
      ),
      body: isPortrait ? _PortraitLayout() : _LandscapeLayout(),
    );
  }
}

// ─── Portrait: top grid + bottom list ────────────────────────────────────────

class _PortraitLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Live view
        AspectRatio(
          aspectRatio: 16 / 9,
          child: const CameraGrid(),
        ),
        const Divider(height: 1),
        // Camera list
        const Expanded(child: _CameraList()),
      ],
    );
  }
}

// ─── Landscape: left grid + right list ───────────────────────────────────────

class _LandscapeLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(flex: 3, child: CameraGrid()),
        const VerticalDivider(width: 1),
        const SizedBox(width: 220, child: _CameraList()),
      ],
    );
  }
}

// ─── Camera List ─────────────────────────────────────────────────────────────

class _CameraList extends ConsumerWidget {
  const _CameraList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCams = ref.watch(cameraListProvider);

    return asyncCams.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text('Lỗi: $e',
            style: const TextStyle(color: AppTheme.danger, fontFamily: 'IBM Plex Mono')),
      ),
      data: (cameras) {
        if (cameras.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline,
                    color: AppTheme.textMuted, size: 36),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có camera nào',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddCameraScreen()),
                  ),
                  child: const Text(
                    '+ THÊM CAMERA',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontFamily: 'IBM Plex Mono',
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: cameras.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (_, i) => _CameraListTile(camera: cameras[i]),
        );
      },
    );
  }
}

class _CameraListTile extends ConsumerWidget {
  const _CameraListTile({required this.camera});
  final CameraModel camera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCams = ref.watch(activeCamerasProvider);
    final isActive = activeCams.any((c) => c.id == camera.id);
    final isFull = activeCams.length >= 4 && !isActive;

    final status = ref.watch(cameraConnectionProvider)[camera.id];

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Stack(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.accent.withOpacity(0.15)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? AppTheme.accent : AppTheme.border,
              ),
            ),
            child: Icon(
              Icons.videocam,
              size: 18,
              color: isActive ? AppTheme.accent : AppTheme.textMuted,
            ),
          ),
          if (isActive && status == ConnectionStatus.connected)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        camera.name,
        style: TextStyle(
          color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontSize: 13,
          fontFamily: 'IBM Plex Mono',
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${_typeName(camera.type)}  •  ${camera.lanIp}:${camera.rtspPort}',
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontFamily: 'IBM Plex Mono',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: AppTheme.textMuted,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddCameraScreen(editCamera: camera),
              ),
            ),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppTheme.textMuted,
            onPressed: () => _confirmDelete(context, ref),
          ),
          // Add/Remove from view
          GestureDetector(
            onTap: isFull
                ? null
                : () {
                    final notifier = ref.read(activeCamerasProvider.notifier);
                    if (isActive) {
                      notifier.remove(camera.id);
                    } else {
                      notifier.add(camera);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.danger.withOpacity(0.1)
                    : isFull
                        ? AppTheme.surface
                        : AppTheme.accent.withOpacity(0.1),
                border: Border.all(
                  color: isActive
                      ? AppTheme.danger
                      : isFull
                          ? AppTheme.border
                          : AppTheme.accent,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'DỪNG' : isFull ? 'ĐẦY' : 'XEM',
                style: TextStyle(
                  color: isActive
                      ? AppTheme.danger
                      : isFull
                          ? AppTheme.textMuted
                          : AppTheme.accent,
                  fontSize: 10,
                  fontFamily: 'IBM Plex Mono',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeName(CameraType t) => switch (t) {
        CameraType.hikvision => 'Hikvision',
        CameraType.dahua => 'Dahua',
        CameraType.yosee => 'YoSee',
        CameraType.generic => 'Generic',
      };

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Xóa camera?',
            style: TextStyle(color: AppTheme.textPrimary, fontFamily: 'IBM Plex Mono')),
        content: Text(
          'Bạn có chắc muốn xóa "${camera.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'IBM Plex Mono', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('XÓA', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(activeCamerasProvider.notifier).remove(camera.id);
      await ref.read(cameraRepositoryProvider).delete(camera.id);
    }
  }
}
