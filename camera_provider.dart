import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/camera_model.dart';

// ─── Isar Database ──────────────────────────────────────────────────────────

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    [CameraModelSchema],
    directory: dir.path,
  );
});

// ─── Camera Repository ───────────────────────────────────────────────────────

class CameraRepository {
  CameraRepository(this._isar);
  final Isar _isar;

  Future<List<CameraModel>> getAll() async {
    return await _isar.cameraModels.where().findAll();
  }

  Stream<List<CameraModel>> watchAll() {
    return _isar.cameraModels.where().watch(fireImmediately: true);
  }

  Future<void> add(CameraModel cam) async {
    await _isar.writeTxn(() => _isar.cameraModels.put(cam));
  }

  Future<void> update(CameraModel cam) async {
    await _isar.writeTxn(() => _isar.cameraModels.put(cam));
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.cameraModels.delete(id));
  }
}

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return CameraRepository(isar);
});

// ─── Camera List (stream từ Isar) ────────────────────────────────────────────

final cameraListProvider = StreamProvider<List<CameraModel>>((ref) {
  final repo = ref.watch(cameraRepositoryProvider);
  return repo.watchAll();
});

// ─── Active Cameras (tối đa 4 camera đang xem) ──────────────────────────────

class ActiveCamerasNotifier extends StateNotifier<List<CameraModel>> {
  ActiveCamerasNotifier() : super([]);

  static const int maxCameras = 4;

  bool add(CameraModel cam) {
    if (state.length >= maxCameras) return false;
    if (state.any((c) => c.id == cam.id)) return false;
    state = [...state, cam];
    return true;
  }

  void remove(int id) {
    state = state.where((c) => c.id != id).toList();
  }

  void clear() => state = [];

  void replace(int index, CameraModel cam) {
    final list = [...state];
    list[index] = cam;
    state = list;
  }
}

final activeCamerasProvider =
    StateNotifierProvider<ActiveCamerasNotifier, List<CameraModel>>(
  (ref) => ActiveCamerasNotifier(),
);

// ─── Connection State per Camera ─────────────────────────────────────────────

enum ConnectionStatus { idle, connecting, connected, error, reconnecting }

class CameraConnectionNotifier
    extends StateNotifier<Map<int, ConnectionStatus>> {
  CameraConnectionNotifier() : super({});

  void setStatus(int cameraId, ConnectionStatus status) {
    state = {...state, cameraId: status};
  }

  ConnectionStatus getStatus(int cameraId) {
    return state[cameraId] ?? ConnectionStatus.idle;
  }
}

final cameraConnectionProvider =
    StateNotifierProvider<CameraConnectionNotifier, Map<int, ConnectionStatus>>(
  (ref) => CameraConnectionNotifier(),
);

// ─── Layout Mode ─────────────────────────────────────────────────────────────

enum GridLayout { single, two, four }

final gridLayoutProvider = StateProvider<GridLayout>((ref) {
  final count = ref.watch(activeCamerasProvider).length;
  if (count <= 1) return GridLayout.single;
  if (count <= 2) return GridLayout.two;
  return GridLayout.four;
});
