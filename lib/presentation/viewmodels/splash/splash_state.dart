import 'package:equatable/equatable.dart';

enum SplashTarget {
  initial,
  intro,
  login,
  pinLock,
  profile,
  deviceCompromised,
}

class SplashState extends Equatable {
  final SplashTarget target;

  const SplashState({this.target = SplashTarget.initial});

  @override
  List<Object?> get props => [target];
}
