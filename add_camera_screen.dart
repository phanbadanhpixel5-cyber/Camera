import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/camera_model.dart';
import '../providers/camera_provider.dart';

class AddCameraScreen extends ConsumerStatefulWidget {
  const AddCameraScreen({super.key, this.editCamera});
  final CameraModel? editCamera;

  @override
  ConsumerState<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends ConsumerState<AddCameraScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _lanIpCtrl;
  late TextEditingController _wanIpCtrl;
  late TextEditingController _domainCtrl;
  late TextEditingController _rtspPortCtrl;
  late TextEditingController _onvifPortCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _customPathCtrl;

  CameraType _type = CameraType.hikvision;
  StreamQuality _quality = StreamQuality.main;
  bool _testingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final cam = widget.editCamera;
    _nameCtrl = TextEditingController(text: cam?.name ?? '');
    _lanIpCtrl = TextEditingController(text: cam?.lanIp ?? '');
    _wanIpCtrl = TextEditingController(text: cam?.wanIp ?? '');
    _domainCtrl = TextEditingController(text: cam?.domain ?? '');
    _rtspPortCtrl =
        TextEditingController(text: (cam?.rtspPort ?? 554).toString());
    _onvifPortCtrl =
        TextEditingController(text: (cam?.onvifPort ?? 8000).toString());
    _userCtrl = TextEditingController(text: cam?.username ?? 'admin');
    _passCtrl = TextEditingController(text: cam?.password ?? '');
    _customPathCtrl =
        TextEditingController(text: cam?.customRtspPath ?? '/live/main');
    if (cam != null) {
      _type = cam.type;
      _quality = cam.quality;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _lanIpCtrl, _wanIpCtrl, _domainCtrl,
      _rtspPortCtrl, _onvifPortCtrl, _userCtrl, _passCtrl, _customPathCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  CameraModel _buildModel() {
    final cam = widget.editCamera ?? CameraModel();
    cam
      ..name = _nameCtrl.text.trim()
      ..lanIp = _lanIpCtrl.text.trim()
      ..wanIp = _wanIpCtrl.text.trim().isEmpty ? null : _wanIpCtrl.text.trim()
      ..domain = _domainCtrl.text.trim().isEmpty ? null : _domainCtrl.text.trim()
      ..rtspPort = int.tryParse(_rtspPortCtrl.text) ?? 554
      ..onvifPort = int.tryParse(_onvifPortCtrl.text) ?? 8000
      ..username = _userCtrl.text.trim()
      ..password = _passCtrl.text
      ..type = _type
      ..quality = _quality
      ..customRtspPath = _type == CameraType.generic ? _customPathCtrl.text.trim() : null;
    return cam;
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });

    final cam = _buildModel();
    final url = cam.buildRtspUrl();

    try {
      // Test TCP socket to RTSP port
      final uri = Uri.parse(url);
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      setState(() {
        _testSuccess = true;
        _testResult = '✓ Kết nối thành công tới ${uri.host}:${uri.port}';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = '✗ Không kết nối được: $e';
      });
    } finally {
      setState(() => _testingConnection = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(cameraRepositoryProvider);
    await repo.add(_buildModel());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editCamera != null;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(isEdit ? 'EDIT CAMERA' : 'ADD CAMERA'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'LƯU',
              style: TextStyle(
                color: AppTheme.accent,
                fontFamily: 'IBM Plex Mono',
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel('THÔNG TIN CƠ BẢN'),
            const SizedBox(height: 8),
            _Field(controller: _nameCtrl, label: 'Tên camera', required: true),
            const SizedBox(height: 12),

            // Camera type
            _SectionLabel('LOẠI CAMERA'),
            const SizedBox(height: 8),
            _TypeSelector(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),

            _SectionLabel('KẾT NỐI'),
            const SizedBox(height: 8),
            _Field(
              controller: _lanIpCtrl,
              label: 'IP LAN (bắt buộc)',
              hint: '192.168.1.100',
              required: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _wanIpCtrl,
              label: 'IP WAN (tùy chọn)',
              hint: '203.x.x.x',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _domainCtrl,
              label: 'Domain/DDNS (tùy chọn)',
              hint: 'camera.example.com',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _rtspPortCtrl,
                    label: 'RTSP Port',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _onvifPortCtrl,
                    label: 'ONVIF Port',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionLabel('XÁC THỰC'),
            const SizedBox(height: 8),
            _Field(controller: _userCtrl, label: 'Username', required: true),
            const SizedBox(height: 12),
            _Field(
              controller: _passCtrl,
              label: 'Password',
              obscure: true,
              required: true,
            ),
            const SizedBox(height: 16),

            // Stream quality
            _SectionLabel('CHẤT LƯỢNG STREAM'),
            const SizedBox(height: 8),
            _QualitySelector(
              selected: _quality,
              onChanged: (q) => setState(() => _quality = q),
            ),
            const SizedBox(height: 12),

            // Generic path
            if (_type == CameraType.generic) ...[
              _SectionLabel('RTSP PATH'),
              const SizedBox(height: 8),
              _Field(
                controller: _customPathCtrl,
                label: 'Custom RTSP Path',
                hint: '/live/main',
              ),
              const SizedBox(height: 12),
            ],

            // RTSP URL preview
            _RtspPreview(camera: _buildModel()),
            const SizedBox(height: 16),

            // Test connection
            ElevatedButton.icon(
              onPressed: _testingConnection ? null : _testConnection,
              icon: _testingConnection
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.bg,
                      ),
                    )
                  : const Icon(Icons.network_ping, size: 18),
              label: Text(_testingConnection ? 'ĐANG TEST...' : 'TEST KẾT NỐI'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppTheme.accentDim,
                foregroundColor: AppTheme.accent,
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_testSuccess ? AppTheme.success : AppTheme.danger)
                      .withOpacity(0.1),
                  border: Border.all(
                    color: _testSuccess ? AppTheme.success : AppTheme.danger,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testSuccess ? AppTheme.success : AppTheme.danger,
                    fontSize: 12,
                    fontFamily: 'IBM Plex Mono',
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 10,
          letterSpacing: 2,
          fontFamily: 'IBM Plex Mono',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontFamily: 'IBM Plex Mono',
        fontSize: 13,
      ),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null
          : null,
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});
  final CameraType selected;
  final ValueChanged<CameraType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: CameraType.values.map((type) {
        final active = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
              border: Border.all(
                color: active ? AppTheme.accent : AppTheme.border,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type.name.toUpperCase(),
              style: TextStyle(
                color: active ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 11,
                fontFamily: 'IBM Plex Mono',
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.selected, required this.onChanged});
  final StreamQuality selected;
  final ValueChanged<StreamQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: StreamQuality.values.map((q) {
        final active = q == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(q),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
                border: Border.all(color: active ? AppTheme.accent : AppTheme.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  q == StreamQuality.main ? 'MAIN STREAM' : 'SUB STREAM',
                  style: TextStyle(
                    color: active ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 11,
                    fontFamily: 'IBM Plex Mono',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RtspPreview extends StatelessWidget {
  const _RtspPreview({required this.camera});
  final CameraModel camera;

  @override
  Widget build(BuildContext context) {
    String url = '';
    try {
      url = camera.buildRtspUrl();
    } catch (_) {
      url = '—';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RTSP URL PREVIEW',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              letterSpacing: 2,
              fontFamily: 'IBM Plex Mono',
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            url,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 11,
              fontFamily: 'IBM Plex Mono',
            ),
          ),
        ],
      ),
    );
  }
}
