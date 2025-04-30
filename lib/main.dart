import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kursovoi1/firebase_options.dart';
import 'package:kursovoi1/screens/auth/login_screen.dart';
import 'package:kursovoi1/screens/main_screen.dart';
import 'package:kursovoi1/theme/app_theme.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('ru_RU', null);
    print('Firebase успешно инициализирован');
  } catch (e) {
    print('Ошибка инициализации Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Такси',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper: состояние аутентификации - ${snapshot.connectionState}');
        print('AuthWrapper: данные пользователя - ${snapshot.data?.email}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Ошибка в StreamBuilder: ${snapshot.error}');
          return const LoginScreen();
        }

        final user = snapshot.data;
        if (user == null || user.id.isEmpty) {
          print('Пользователь не авторизован, показываем экран входа');
          return const LoginScreen();
        }

        print('Пользователь авторизован, показываем MainScreen');
        return const MainScreen();
      },
    );
  }
}
