import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../utils/constants.dart';

class ProfileSwitcher extends StatelessWidget {
  final List<UserProfile> profiles;
  final UserProfile? activeProfile;
  final ValueChanged<UserProfile> onProfileSelected;
  final VoidCallback onAddProfile;

  const ProfileSwitcher({
    super.key,
    required this.profiles,
    required this.activeProfile,
    required this.onProfileSelected,
    required this.onAddProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (activeProfile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        onSelected: (value) {
          if (value == 'add_new') {
            onAddProfile();
          } else {
            final selected = profiles.firstWhere((p) => p.id == value);
            onProfileSelected(selected);
          }
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[];

          for (final p in profiles) {
            final isCurrent = p.id == activeProfile!.id;
            items.add(
              PopupMenuItem<String>(
                value: p.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isCurrent ? AppColors.primary : AppColors.surfaceLight,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }

          items.add(const PopupMenuDivider());
          items.add(
            const PopupMenuItem<String>(
              value: 'add_new',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Add New Profile',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );

          return items;
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                activeProfile!.name.isNotEmpty ? activeProfile!.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ACTIVE PROFILE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  activeProfile!.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
