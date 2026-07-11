import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/presentation/providers/squad_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Create or join a squad for shared Wake Up Tax accountability.
class SquadSheet extends ConsumerStatefulWidget {
  const SquadSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SquadSheet(),
    );
  }

  @override
  ConsumerState<SquadSheet> createState() => _SquadSheetState();
}

class _SquadSheetState extends ConsumerState<SquadSheet> {
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
          : 'Squad live. Invite code: $id — bailouts hit everyone.';
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
          : 'Joined. Bailouts hit everyone. No negotiating.';
    });
    if (id != null) {
      ref.invalidate(currentSquadIdProvider);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadId = ref.watch(currentSquadIdProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.cardRadius),
          ),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedForeground.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SQUAD TAXES',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                squadId == null
                    ? 'Link alarms with up to a few mates. One bailout hits the whole squad next day.'
                    : 'You are in a squad. Live rep bars appear during Wake Up Tax.',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (squadId == null) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(
                    labelText: 'Squad name',
                    labelStyle: TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _busy ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('CREATE SQUAD'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(
                    labelText: 'Invite code',
                    labelStyle: TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _busy ? null : _join,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foreground,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('JOIN WITH CODE'),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(
                  _message!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
