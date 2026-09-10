import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileState());

  Future<void> loadProfile({bool isPullToRefresh = false}) async {
    if (!isPullToRefresh && state.status != ProfileStatus.success) {
      emit(state.copyWith(status: ProfileStatus.loading, errorMessage: null));
    }

    try {
      final result = await _profileRepository.getProfile(forceRefresh: isPullToRefresh);
      emit(state.copyWith(
        status: ProfileStatus.success,
        user: result.user,
        isOffline: result.isOffline,
        cachedAt: result.cachedAt,
        cipherMode: result.cipherMode,
        sessionStartTime: result.isOffline ? state.sessionStartTime : DateTime.now(),
        errorMessage: null,
      ));
    } catch (e) {
      // Check if we can fallback to cached profile
      final cached = await _profileRepository.getCachedProfile();
      if (cached != null) {
        emit(state.copyWith(
          status: ProfileStatus.success,
          user: cached.user,
          isOffline: true,
          cachedAt: cached.cachedAt,
          cipherMode: cached.cipherMode,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: ErrorFormatter.format(e),
        ));
      }
    }
  }

  void notifySessionRefreshed() {
    if (state.status == ProfileStatus.success && !state.isOffline) {
      emit(state.copyWith(sessionStartTime: DateTime.now()));
    }
  }
}
