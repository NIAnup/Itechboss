import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/secure_storage_datasource.dart';
import '../../domain/repositories/pin_repository.dart';
import '../viewmodels/pin/pin_cubit.dart';
import '../views/pin/pin_lock_screen.dart';

class AppLifecyclePinBarrier extends StatefulWidget {
  final Widget child;

  const AppLifecyclePinBarrier({super.key, required this.child});

  @override
  State<AppLifecyclePinBarrier> createState() => _AppLifecyclePinBarrierState();
}

class _AppLifecyclePinBarrierState extends State<AppLifecyclePinBarrier>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _checkAndLockOnBackground();
    }
  }

  Future<void> _checkAndLockOnBackground() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final secureStorage = context.read<SecureStorageDataSource>();
      final hasPin = await secureStorage.hasPinSet();
      final tokens = await secureStorage.getTokens();
      final hasToken = tokens != null && tokens.accessToken.isNotEmpty;

      if (hasPin && hasToken && mounted) {
        setState(() {
          _isLocked = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking PIN lock status on background: $e');
    } finally {
      _isChecking = false;
    }
  }

  void _onUnlocked() {
    if (mounted) {
      setState(() {
        _isLocked = false;
      });
    }
  }

  void _onLogout() {
    if (mounted) {
      setState(() {
        _isLocked = false;
      });
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: BlocProvider<PinCubit>(
                create: (ctx) => PinCubit(ctx.read<PinRepository>()),
                child: PinLockScreen(
                  onUnlocked: _onUnlocked,
                  onLogout: _onLogout,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
