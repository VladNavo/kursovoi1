import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { admin, driver, passenger }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoURL;
  final String phone;
  final UserRole role;
  final List<String> bookings;
  final int bonusPoints;
  final String? displayName;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoURL,
    required this.phone,
    required this.role,
    this.bookings = const [],
    this.bonusPoints = 0,
    this.displayName,
  });

  static UserModel empty() {
    return const UserModel(
      id: '',
      name: 'Пользователь',
      email: '',
      phone: '',
      role: UserRole.passenger,
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
      role: UserRole.passenger,
      bonusPoints: 0,
      bookings: const [],
      photoURL: user.photoURL,
      displayName: user.displayName,
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
      photoURL: user.photoURL,
      displayName: user.displayName,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      photoURL: map['photoURL'] as String?,
      phone: map['phone'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == (map['role'] as String),
        orElse: () => UserRole.passenger,
      ),
      bookings: (map['bookings'] as List<dynamic>?)?.cast<String>() ?? const [],
      bonusPoints: (map['bonusPoints'] as int?) ?? 0,
      displayName: map['displayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'phone': phone,
      'role': role.toString().split('.').last,
      'bookings': bookings,
      'bonusPoints': bonusPoints,
      'displayName': displayName,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'phone': phone,
      'role': role.toString().split('.').last,
      'bookings': bookings,
      'bonusPoints': bonusPoints,
      'displayName': displayName,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoURL,
    String? phone,
    UserRole? role,
    List<String>? bookings,
    int? bonusPoints,
    String? displayName,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      bookings: bookings ?? this.bookings,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoURL,
        phone,
        role,
        bookings,
        bonusPoints,
        displayName,
      ];
} 