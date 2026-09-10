import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/preferences_datasource.dart';
import '../../viewmodels/pin/pin_state.dart';
import '../../viewmodels/settings/settings_cubit.dart';
import '../../viewmodels/settings/settings_state.dart';
import '../../viewmodels/theme/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int _currentNavIndex = 1;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out of VAULT?'),
          content: const Text(
            'This will clear your active session, delete the encrypted local cache, and wipe your PIN security key.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<SettingsCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemePref = context.watch<ThemeCubit>().currentPreference;

    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.isLoggedOut) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Settings'),
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
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Section 1: APPEARANCE
                _buildSectionHeader('APPEARANCE', isDark),
                const SizedBox(height: 10),
                _buildThemeSelector(context, currentThemePref, isDark),

                const SizedBox(height: 28),

                // Section 2: SECURITY
                _buildSectionHeader('SECURITY', isDark),
                const SizedBox(height: 10),
                _buildCard(
                  isDark: isDark,
                  children: [
                    InkWell(
                      onTap: () async {
                        final settingsCubit = context.read<SettingsCubit>();
                        await Navigator.of(context)
                            .pushNamed('/set_pin', arguments: PinFlowMode.create);
                        if (!mounted) return;
                        settingsCubit.loadSettings();
                      },
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'App lock PIN',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: state.isPinSet
                                        ? AppColors.successGreenLight
                                        : (isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    state.isPinSet ? 'Enabled' : 'Not set',
                                    style: TextStyle(
                                      color: state.isPinSet
                                          ? AppColors.successGreen
                                          : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorderLight),
                    InkWell(
                      onTap: state.isPinSet
                          ? () async {
                              final settingsCubit = context.read<SettingsCubit>();
                              await Navigator.of(context)
                                  .pushNamed('/set_pin', arguments: PinFlowMode.change);
                              if (!mounted) return;
                              settingsCubit.loadSettings();
                            }
                          : null,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Change PIN',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: state.isPinSet
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Section 3: SESSION
                _buildSectionHeader('SESSION', isDark),
                const SizedBox(height: 10),
                _buildCard(
                  isDark: isDark,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Signed in as',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            '@${state.username}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorderLight),
                    InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.errorRed,
                              ),
                            ),
                            Icon(
                              Icons.logout,
                              size: 18,
                              color: AppColors.errorRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Footer version mark
                Center(
                  child: Text(
                    'VAULT v1.0.0 · build 1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    AppThemeModePreference currentMode,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildThemeTab(context, 'Light', AppThemeModePreference.light, currentMode, isDark),
          _buildThemeTab(context, 'Dark', AppThemeModePreference.dark, currentMode, isDark),
          _buildThemeTab(context, 'System', AppThemeModePreference.system, currentMode, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeTab(
    BuildContext context,
    String title,
    AppThemeModePreference mode,
    AppThemeModePreference currentMode,
    bool isDark,
  ) {
    final isSelected = mode == currentMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<ThemeCubit>().setTheme(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : AppColors.primaryNavy)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.primaryNavy : Colors.white)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Column(children: children),
    );
  }
}
