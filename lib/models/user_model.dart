import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { user, driver, admin }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final int bonusPoints;
  final List<String> bookings;
  final String? displayName;
  final String? photoURL;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = UserRole.user,
    this.bonusPoints = 0,
    this.bookings = const [],
    this.displayName,
    this.photoURL,
  });

  static UserModel empty() {
    return const UserModel(
      id: '',
      name: 'Пользователь',
      email: '',
      phone: '',
      role: UserRole.user,
      bonusPoints: 0,
      bookings: [],
    );
  }

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@')[0] ?? 'Пользователь',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      role: UserRole.user,
      bonusPoints: 0,
      bookings: const [],
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  factory UserModel.fromFirebaseUserWithRole(User user, UserRole role) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@')[0] ?? 'Пользователь',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      role: role,
      bonusPoints: 0,
      bookings: const [],
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString(),
      'bonusPoints': bonusPoints,
      'bookings': bookings,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        bonusPoints,
        bookings,
        displayName,
        photoURL,
      ];
} 