import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserModel? user;
  final bool isOffline;
  final DateTime? cachedAt;
  final String cipherMode;
  final DateTime sessionStartTime;
  final String? errorMessage;

  ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.isOffline = false,
    this.cachedAt,
    this.cipherMode = 'AES-256-GCM',
    DateTime? sessionStartTime,
    this.errorMessage,
  }) : sessionStartTime = sessionStartTime ?? DateTime.now();

  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    bool? isOffline,
    DateTime? cachedAt,
    String? cipherMode,
    DateTime? sessionStartTime,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt ?? this.cachedAt,
      cipherMode: cipherMode ?? this.cipherMode,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        isOffline,
        cachedAt,
        cipherMode,
        sessionStartTime,
        errorMessage,
      ];
}
