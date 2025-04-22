import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kursovoi1/models/user_model.dart';
import 'package:kursovoi1/screens/admin/admin_routes_screen.dart';
import 'package:kursovoi1/screens/driver/driver_routes_screen.dart';
import 'package:kursovoi1/screens/home_screen.dart';
import 'package:kursovoi1/screens/profile_screen.dart';
import 'package:kursovoi1/screens/auth/login_screen.dart';
import 'package:kursovoi1/services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _authService = AuthService();
  UserModel? _currentUser;
  int _selectedIndex = 0;
  StreamSubscription<UserModel?>? _authSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      // Сначала загружаем текущего пользователя
      final user = await _authService.currentUser;
      print('MainScreen: инициализация пользователя - ${user?.email}');
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }

      // Затем подписываемся на изменения
      _authSubscription = _authService.authStateChanges.listen((user) {
        print('MainScreen: получено обновление пользователя - ${user?.email}');
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('MainScreen: ошибка при инициализации пользователя - $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // Перенаправляем на экран входа
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Удаляем все предыдущие экраны из стека
        );
      }
    } catch (e) {
      print('Ошибка при выходе: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при выходе из аккаунта')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MainScreen: построение с пользователем - ${_currentUser?.email}');
    
    if (_isLoading) {
      print('MainScreen: загрузка данных пользователя');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      print('MainScreen: пользователь не авторизован');
      // Перенаправляем на экран входа
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Widget _getScreen() {
      switch (_currentUser!.role) {
        case UserRole.admin:
          print('MainScreen: показываем экран администратора');
          return const AdminRoutesScreen();
        case UserRole.driver:
          print('MainScreen: показываем экран водителя');
          return const DriverRoutesScreen();
        case UserRole.user:
          print('MainScreen: показываем экран пользователя');
          return const HomeScreen();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? (_currentUser!.role == UserRole.admin
                  ? 'Маршруты'
                  : _currentUser!.role == UserRole.driver
                      ? 'Мои маршруты'
                      : 'Главная')
              : 'Профиль',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _initializeUser();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          await _initializeUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _getScreen(),
                const ProfileScreen(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _currentUser!.role == UserRole.admin
                ? 'Маршруты'
                : _currentUser!.role == UserRole.driver
                    ? 'Мои маршруты'
                    : 'Главная',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
} 