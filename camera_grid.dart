import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_provider.dart';
import 'camera_tile.dart';

class CameraGrid extends ConsumerWidget {
  const CameraGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(activeCamerasProvider);

    if (cameras.isEmpty) return const _EmptyGrid();

    if (cameras.length == 1) {
      return CameraTile(camera: cameras[0]);
    }

    if (cameras.length == 2) {
      return Column(
        children: cameras
            .map((cam) => Expanded(child: CameraTile(camera: cam)))
            .toList(),
      );
    }

    // 3 or 4 cameras → 2x2 grid
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 9,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: cameras.length,
      itemBuilder: (_, i) => CameraTile(camera: cameras[i]),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CCTV icon with glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF21262D), width: 1),
              color: const Color(0xFF111419),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              size: 36,
              color: Color(0xFF484F58),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'NO CAMERAS ACTIVE',
            style: TextStyle(
              color: Color(0xFF7D8590),
              fontSize: 12,
              letterSpacing: 3,
              fontFamily: 'IBM Plex Mono',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn camera từ danh sách để bắt đầu xem',
            style: TextStyle(
              color: Color(0xFF484F58),
              fontSize: 11,
              fontFamily: 'IBM Plex Mono',
            ),
          ),
        ],
      ),
    );
  }
}
