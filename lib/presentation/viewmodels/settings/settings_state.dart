import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isPinSet;
  final String username;
  final bool isLoggedOut;

  const SettingsState({
    this.isPinSet = false,
    this.username = 'emilys',
    this.isLoggedOut = false,
  });

  SettingsState copyWith({
    bool? isPinSet,
    String? username,
    bool? isLoggedOut,
  }) {
    return SettingsState(
      isPinSet: isPinSet ?? this.isPinSet,
      username: username ?? this.username,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
    );
  }

  @override
  List<Object?> get props => [isPinSet, username, isLoggedOut];
}
