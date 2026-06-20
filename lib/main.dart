import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/services/sound_service.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Permite que múltiplos AudioPlayers toquem simultaneamente sem disputar foco.
  // Contexto global para efeitos sonoros: ambient no iOS (mistura sem tomar sessão),
  // sem foco de áudio no Android (não interrompe outros apps).
  AudioPlayer.global.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.none,
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioMode: AndroidAudioMode.normal,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: {},
      ),
    ),
  );
  runApp(const ProviderScope(child: ShonenQuizApp()));
}

class _SoundPreloader extends ConsumerStatefulWidget {
  final Widget child;
  const _SoundPreloader({required this.child});

  @override
  ConsumerState<_SoundPreloader> createState() => _SoundPreloaderState();
}

class _SoundPreloaderState extends ConsumerState<_SoundPreloader> {
  @override
  void initState() {
    super.initState();
    ref.read(soundServiceProvider).preloadAll();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ShonenQuizApp extends ConsumerWidget {
  const ShonenQuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onSessionExpired = () => ref.read(authStatusProvider.notifier).logout();
    final router = ref.watch(routerProvider);
    return _SoundPreloader(
      child: MaterialApp.router(
        title: 'Shonen Quest',
        theme: AppTheme.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
