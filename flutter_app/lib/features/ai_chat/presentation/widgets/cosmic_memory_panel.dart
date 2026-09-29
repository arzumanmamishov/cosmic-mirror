import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// CosmicMemoryPanel surfaces what the AI astrologer remembers about the user
/// — recurring themes, ongoing transits, and key concerns from prior chats.
/// Over time this becomes the strongest signal that Lively *knows* the user.
class CosmicMemoryPanel extends StatelessWidget {
  const CosmicMemoryPanel({super.key});

  // Mock memory items. In production these are extracted server-side
  // from the user's chat history + current transits.
  static List<_Memory> _memories(AppLocalizations l) => [
        _Memory(
          icon: Icons.swap_vert_rounded,
          label: l.aiMemorySaturnReturnLabel,
          detail: l.aiMemorySaturnReturnDetail,
          color: const Color(0xFF7B61FF),
        ),
        _Memory(
          icon: Icons.work_rounded,
          label: l.aiMemoryCareerLabel,
          detail: l.aiMemoryCareerDetail,
          color: const Color(0xFFB8860B),
        ),
        _Memory(
          icon: Icons.favorite_rounded,
          label: l.aiMemoryPartnerLabel,
          detail: l.aiMemoryPartnerDetail,
          color: const Color(0xFFE14B8A),
        ),
        _Memory(
          icon: Icons.spa_rounded,
          label: l.aiMemorySelfTrustLabel,
          detail: l.aiMemorySelfTrustDetail,
          color: const Color(0xFF5ED39A),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.primary.withValues(alpha: 0.14),
            p.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.psychology_rounded,
                  size: 16,
                  color: p.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.aiMemoryTitle,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.aiMemorySubtitle,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.success.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l.aiMemoryLive,
                style: TextStyle(
                  color: p.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._memories(l).map((m) => _MemoryRow(memory: m)),
        ],
      ),
    );
  }
}

class _Memory {
  const _Memory({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color color;
}

class _MemoryRow extends StatelessWidget {
  const _MemoryRow({required this.memory});
  final _Memory memory;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: memory.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(memory.icon, color: memory.color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.label,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  memory.detail,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
