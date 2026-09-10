import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_formatter.dart';
import '../../viewmodels/profile/profile_cubit.dart';
import '../../viewmodels/profile/profile_state.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/session_timer_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) {
      Navigator.of(context).pushNamed('/settings').then((_) {
        if (mounted) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () {
              context.read<ProfileCubit>().loadProfile(isPullToRefresh: true);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.user == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryNavy,
              ),
            );
          }

          if (state.status == ProfileStatus.failure && state.user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 54, color: AppColors.textMutedLight),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Failed to load profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProfileCubit>().loadProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(160, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<ProfileCubit>().loadProfile(isPullToRefresh: true);
            },
            color: AppColors.primaryNavy,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Top Offline Warning Banner (if offline)
                if (state.isOffline && state.cachedAt != null)
                  OfflineBanner(lastSyncedAt: state.cachedAt!),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar Circle with initials
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A5F),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Full Name
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Username
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Badge (Online Session Active vs Offline Decrypted)
                      if (!state.isOffline)
                        SessionTimerChip(sessionStartTime: state.sessionStartTime)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: Color(0xFFB45309)),
                              SizedBox(width: 6),
                              Text(
                                'Decrypted from local cache',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 28),

                      // ACCOUNT Card
                      _buildSectionHeader('ACCOUNT', isDark),
                      const SizedBox(height: 8),
                      _buildCard(
                        isDark: isDark,
                        children: [
                          _buildDataRow(
                            label: 'Email',
                            value: user.email,
                            isDark: isDark,
                          ),
                          const Divider(height: 1, color: AppColors.cardBorderLight),
                          _buildDataRow(
                            label: 'Gender',
                            value: user.gender.isNotEmpty
                                ? '${user.gender[0].toUpperCase()}${user.gender.substring(1)}'
                                : '-',
                            isDark: isDark,
                          ),
                          if (!state.isOffline) ...[
                            const Divider(height: 1, color: AppColors.cardBorderLight),
                            _buildDataRow(
                              label: 'User ID',
                              value: user.id.toString(),
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),

                      // LOCAL COPY Card (when online or when cached info exists)
                      if (!state.isOffline && state.cachedAt != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('LOCAL COPY', isDark),
                        const SizedBox(height: 8),
                        _buildCard(
                          isDark: isDark,
                          children: [
                            _buildDataRow(
                              label: 'Encryption',
                              value: state.cipherMode,
                              isDark: isDark,
                            ),
                            const Divider(height: 1, color: AppColors.cardBorderLight),
                            _buildDataRow(
                              label: 'Cache updated',
                              value: TimeFormatter.formatRelativeTime(state.cachedAt!),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],

                      // If offline: Try Again Button
                      if (state.isOffline) ...[
                        const SizedBox(height: 28),
                        OutlinedButton(
                          onPressed: () {
                            context.read<ProfileCubit>().loadProfile(isPullToRefresh: true);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Try again',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'Pull down to refresh',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
