import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? errorMessage;
  final bool isPasswordVisible;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.isPasswordVisible = false,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    bool? isPasswordVisible,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, isPasswordVisible];
}
