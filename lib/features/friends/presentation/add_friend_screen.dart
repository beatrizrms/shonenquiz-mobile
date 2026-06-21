import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../data/friends_models.dart';
import '../data/friends_repository.dart';
import '../providers/friends_provider.dart';
import 'widgets/friend_avatar.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    if (v.length >= 8) {
      ref.read(friendSearchProvider.notifier).search(v);
    } else {
      ref.read(friendSearchProvider.notifier).clear();
    }
  }

  Future<void> _sendRequest(String friendCode) async {
    setState(() => _sending = true);
    try {
      await ref.read(friendsRepositoryProvider).sendRequest(friendCode);
      ref.invalidate(friendsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada!'), backgroundColor: AppColors.green),
      );
      ref.read(friendSearchProvider.notifier).clear();
      _ctrl.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myCodeAsync = ref.watch(myFriendCodeProvider);
    final searchState = ref.watch(friendSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Adicionar amigo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Meu código
          myCodeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (code) => _MyCodeCard(code: code),
          ),
          const SizedBox(height: 20),

          // ── Busca
          const Text('BUSCAR POR CÓDIGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .12)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 3, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Ex: GOKU7F3A',
              hintStyle: const TextStyle(color: AppColors.textMuted, letterSpacing: 1),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryPurple)),
              suffixIcon: searchState.isLoading
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple)))
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // ── Resultado da busca
          searchState.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => _ErrorCard(message: e is ApiException ? e.message : 'Código não encontrado'),
            data: (profile) => profile == null
                ? const SizedBox.shrink()
                : _SearchResultCard(profile: profile, sending: _sending, onSend: () => _sendRequest(profile.friendCode)),
          ),
        ],
      ),
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  final String code;
  const _MyCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEU CÓDIGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(code, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 4)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado!'), duration: Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: AppColors.lightPurple),
                      SizedBox(width: 5),
                      Text('Copiar', style: TextStyle(fontSize: 12, color: AppColors.lightPurple, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Compartilhe para que outros possam te adicionar', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final FriendProfile profile;
  final bool sending;
  final VoidCallback onSend;

  const _SearchResultCard({required this.profile, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final alreadyFriend = profile.friendshipStatus == 'accepted';
    final pending = profile.friendshipStatus == 'pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.selectionPurple),
      ),
      child: Column(
        children: [
          Row(
            children: [
              FriendAvatar(size: 50, level: profile.level),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.username, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${profile.levelTitle} · ${profile.leagueLabel}',
                        style: const TextStyle(fontSize: 12, color: AppColors.lightPurple, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatsRow(stats: profile.stats),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: alreadyFriend || pending || sending ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                disabledBackgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      alreadyFriend ? '✓ Já são amigos' : pending ? 'Solicitação enviada' : 'Enviar solicitação',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: alreadyFriend || pending ? AppColors.textMuted : Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final FriendStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('${stats.totalSessions}', 'Partidas'),
      ('${stats.accuracy}%', 'Precisão'),
      ('🔥 ${stats.maxCombo}', 'Maior combo'),
    ];
    return Row(
      children: items.map((s) => Expanded(
        child: Column(
          children: [
            Text(s.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(s.$2, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      )).toList(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.red)),
    );
  }
}
