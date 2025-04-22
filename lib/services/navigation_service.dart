import 'package:flutter/material.dart';
import 'package:kursovoi1/screens/home_screen.dart';
import 'package:kursovoi1/screens/help_screen.dart';
import 'package:kursovoi1/screens/profile_screen.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateToScreen(int index, BuildContext context) async {
    switch (index) {
      case 0:
        // Поиск - уже на главном экране
        if (context.widget is! HomeScreen) {
          return await navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
        break;
      case 1:
        // Помощь
        if (context.widget is! HelpScreen) {
          return await navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HelpScreen(),
            ),
          );
        }
        break;
      case 2:
        // Поездки - пока тот же HomeScreen
        if (context.widget is! HomeScreen) {
          return await navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
        break;
      case 3:
        // Профиль
        if (context.widget is! ProfileScreen) {
          return await navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        }
        break;
    }
  }
} 