import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get firebaseUser => _auth.currentUser;

  // Получить текущего пользователя
  Future<UserModel?> get currentUser async {
    final user = _auth.currentUser;
    if (user == null) return null;

    print('AuthService: получение данных пользователя для ${user.email}');
    print('AuthService: ID пользователя: ${user.uid}');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      print('AuthService: документ пользователя не найден');
      return null;
    }

    final data = doc.data()!;
    print('AuthService: данные пользователя: $data');
    print('AuthService: роль пользователя: ${data['role']}');

    return UserModel.fromMap({...data, 'id': doc.id});
  }

  // Поток для отслеживания состояния аутентификации
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      print('AuthService: изменение состояния аутентификации - ${user?.email}');
      try {
        if (user == null) {
          print('AuthService: пользователь не авторизован');
          return null;
        }
        
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          print('AuthService: документ пользователя не найден');
          return null;
        }

        final data = userDoc.data() as Map<String, dynamic>;
        final bookings = data['bookings'] as List<dynamic>?;
        final roleString = data['role'] as String?;
        print('AuthService: роль пользователя - $roleString');

        final userModel = UserModel(
          id: user.uid,
          name: data['name'] as String? ?? user.displayName ?? user.email?.split('@')[0] ?? 'Пользователь',
          email: data['email'] as String? ?? user.email ?? '',
          phone: data['phone'] as String? ?? user.phoneNumber ?? '',
          role: data['role'] != null
              ? UserRole.values.firstWhere(
                  (e) => e.toString() == 'UserRole.${data['role']}',
                  orElse: () => UserRole.passenger,
                )
              : UserRole.passenger,
          bonusPoints: (data['bonusPoints'] as num?)?.toInt() ?? 0,
          bookings: bookings?.map((e) => e.toString()).toList() ?? const [],
          displayName: data['displayName'] as String? ?? user.displayName,
          photoURL: data['photoURL'] as String? ?? user.photoURL,
        );

        print('AuthService: успешно создан UserModel для ${userModel.email}');
        return userModel;
      } catch (e) {
        print('AuthService: ошибка при обработке изменения состояния аутентификации: $e');
        return null;
      }
    });
  }

  // Регистрация
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.toString().split('.').last,
        'bonusPoints': 0,
        'bookings': <String>[],
        'displayName': name,
        'photoURL': null,
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      return UserModel(
        id: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        bonusPoints: 0,
        bookings: const [],
        displayName: name,
        photoURL: null,
      );
    } catch (e) {
      print('Ошибка при регистрации: $e');
      return null;
    }
  }

  // Вход
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Получаем данные пользователя из Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Обновляем токен пользователя
      await user.getIdToken(true);

      final bookings = data['bookings'] as List<dynamic>?;
      final roleString = data['role'] as String?;

      return UserModel(
        id: user.uid,
        name: data['name'] as String? ?? user.displayName ?? user.email?.split('@')[0] ?? 'Пользователь',
        email: data['email'] as String? ?? user.email ?? '',
        phone: data['phone'] as String? ?? user.phoneNumber ?? '',
        role: data['role'] != null
            ? UserRole.values.firstWhere(
                (e) => e.toString() == 'UserRole.${data['role']}',
                orElse: () => UserRole.passenger,
              )
            : UserRole.passenger,
        bonusPoints: (data['bonusPoints'] as num?)?.toInt() ?? 0,
        bookings: bookings?.map((e) => e.toString()).toList() ?? const [],
        displayName: data['displayName'] as String? ?? user.displayName,
        photoURL: data['photoURL'] as String? ?? user.photoURL,
      );
    } catch (e) {
      print('Ошибка при входе: $e');
      return null;
    }
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Успешный выход из аккаунта');
    } catch (e) {
      print('Ошибка при выходе из аккаунта: $e');
      rethrow;
    }
  }

  // Сброс пароля
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Ошибка при сбросе пароля: $e');
      return false;
    }
  }

  Future<void> updateUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final role = data['role'] as String?;

      if (role != null) {
        await user.getIdToken(true); // Обновляем токен
        print('AuthService: токен пользователя обновлен с ролью $role');
      }
    } catch (e) {
      print('AuthService: ошибка при обновлении токена: $e');
    }
  }

  Future<void> updateUserName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
    });
  }

  Future<UserModel?> _createUserFromFirestore(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return UserModel.fromMap({
        ...data,
        'id': user.uid,
        'name': data['name'] as String? ?? user.displayName ?? 'Пользователь',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'role': data['role'] as String,
        'photoURL': user.photoURL,
      });
    } catch (e) {
      print('AuthService: ошибка при получении данных пользователя - $e');
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }
} 