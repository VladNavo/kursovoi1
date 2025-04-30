import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kursovoi1/models/user_model.dart';
import 'package:kursovoi1/screens/admin/admin_routes_screen.dart';
import 'package:kursovoi1/screens/driver/driver_routes_screen.dart';
import 'package:kursovoi1/screens/home_screen.dart';
import 'package:kursovoi1/screens/profile_screen.dart';
import 'package:kursovoi1/screens/auth/login_screen.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/screens/admin/create_route_screen.dart';
import 'package:kursovoi1/screens/passenger/booking_history_screen.dart';
import 'package:kursovoi1/screens/passenger/routes_screen.dart';

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
      switch (_selectedIndex) {
        case 0:
          if (_currentUser!.role == UserRole.admin) {
            return const AdminRoutesScreen();
          } else if (_currentUser!.role == UserRole.driver) {
            return const DriverRoutesScreen();
          } else {
            return const RoutesScreen();
          }
        case 1:
          return const BookingHistoryScreen();
        case 2:
          return const ProfileScreen();
        default:
          if (_currentUser!.role == UserRole.admin) {
            return const AdminRoutesScreen();
          } else if (_currentUser!.role == UserRole.driver) {
            return const DriverRoutesScreen();
          } else {
            return const RoutesScreen();
          }
      }
    }

    String _getTitle() {
      if (_currentUser!.role == UserRole.passenger) {
        switch (_selectedIndex) {
          case 0:
            return 'Доступные поездки';
          case 1:
            return 'История';
          case 2:
            return 'Профиль';
          default:
            return 'Доступные поездки';
        }
      }
      
      if (_selectedIndex == 1) return 'Профиль';
      switch (_currentUser!.role) {
        case UserRole.admin:
          return 'Управление маршрутами';
        case UserRole.driver:
          return 'Мои маршруты';
        default:
          return 'Доступные поездки';
      }
    }

    String _getBottomNavLabel() {
      switch (_selectedIndex) {
        case 0:
          return 'Маршруты';
        case 1:
          return 'Профиль';
        case 2:
          return 'Профиль';
        default:
          return 'Маршруты';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _getScreen(),
              if (_currentUser!.role == UserRole.passenger)
                const BookingHistoryScreen()
              else
                const ProfileScreen(),
              const ProfileScreen(),
            ],
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
            icon: const Icon(Icons.directions_bus),
            label: _getBottomNavLabel(),
          ),
          if (_currentUser!.role == UserRole.passenger)
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'История',
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