import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/presentation/providers/squad_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SquadsHubScreen extends ConsumerStatefulWidget {
  const SquadsHubScreen({super.key});

  @override
  ConsumerState<SquadsHubScreen> createState() => _SquadsHubScreenState();
}

class _SquadsHubScreenState extends ConsumerState<SquadsHubScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final id = await createSquad(name: name);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = id == null
          ? 'Could not create squad.'
          : 'Squad created successfully!';
    });
    if (id != null) {
      ref.invalidate(currentSquadIdProvider);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final id = await joinSquadByCode(code: code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = id == null
          ? 'Invalid code — check with your squad.'
          : 'Successfully joined squad!';
    });
    if (id != null) {
      ref.invalidate(currentSquadIdProvider);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _nudge(String squadId) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final sent = await nudgeSquad(squadId: squadId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = sent == 0
          ? 'No mates to nudge yet — share your invite code.'
          : 'Nudge sent to $sent mate${sent == 1 ? '' : 's'}.';
    });
    if (sent > 0) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final squadIdAsync = ref.watch(currentSquadIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('SQUAD HUB', style: tt.eyebrow),
        centerTitle: true,
      ),
      body: SafeArea(
        child: squadIdAsync.when(
          data: (squadId) {
            if (squadId == null) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Glassmorphic intro card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 48,
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'SQUAD TAX ACCOUNTABILITY',
                            style: tt.eyebrow.copyWith(color: AppColors.accent),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Link alarms with your friends. If someone fails to wake up, their bailout penalty is split across the entire squad. Work together, wake up together.',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),

                    // Create Squad Form
                    Text('CREATE A SQUAD', style: tt.eyebrow),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.foreground),
                      decoration: InputDecoration(
                        labelText: 'Squad Name',
                        labelStyle: const TextStyle(color: AppColors.mutedForeground),
                        prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy ? null : _create,
                      child: const Text('CREATE SQUAD'),
                    ),

                    const SizedBox(height: 32),

                    // Join Squad Form
                    Text('JOIN SQUAD', style: tt.eyebrow),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeCtrl,
                      style: const TextStyle(color: AppColors.foreground),
                      decoration: InputDecoration(
                        labelText: 'Invite Code',
                        labelStyle: const TextStyle(color: AppColors.mutedForeground),
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : _join,
                      child: const Text('JOIN WITH CODE'),
                    ),

                    if (_message != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _message!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            }

              // User is already in a squad
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active squad details
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ACTIVE SQUAD', style: tt.eyebrow.copyWith(color: AppColors.accent)),
                              const Icon(Icons.groups_rounded, color: AppColors.accent, size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your squad accountability is active. Live workout indicators will trigger during your alarm cycle.',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _busy ? null : () => _nudge(squadId),
                            icon: const Icon(Icons.notifications_active_rounded, size: 18),
                            label: const Text('NUDGE THE SQUAD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Invite code capsule
                    Text('INVITE FRIENDS', style: tt.eyebrow),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            squadId,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy_rounded, size: 18, color: AppColors.primary),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: squadId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Squad ID copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_message != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _message!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading squad: $e')),
        ),
      ),
    );
  }
}
