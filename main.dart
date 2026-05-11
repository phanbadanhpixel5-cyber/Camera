import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/camera_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bg,
    ),
  );

  runApp(
    const ProviderScope(child: IpCameraApp()),
  );
}

class IpCameraApp extends ConsumerWidget {
  const IpCameraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm up the Isar DB early
    ref.watch(isarProvider);

    return MaterialApp(
      title: 'IP Camera Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isarAsync = ref.watch(isarProvider);

    return isarAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'INITIALIZING...',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Text(
            'DB Error: $e',
            style: const TextStyle(color: AppTheme.danger, fontFamily: 'IBM Plex Mono'),
          ),
        ),
      ),
      data: (_) => const HomeScreen(),
    );
  }
}
