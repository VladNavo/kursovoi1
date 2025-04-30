import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/driver/create_route_screen.dart';
import 'package:kursovoi1/screens/driver/route_details_screen.dart';
import 'package:intl/intl.dart';

class DriverRoutesScreen extends StatefulWidget {
  const DriverRoutesScreen({super.key});

  @override
  State<DriverRoutesScreen> createState() => _DriverRoutesScreenState();
}

class _DriverRoutesScreenState extends State<DriverRoutesScreen> {
  final _routeService = RouteService();
  final _authService = AuthService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  UserModel? _currentUser;
  bool _showCompletedRoutes = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showCompletedRoutes = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showCompletedRoutes
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      foregroundColor: !_showCompletedRoutes
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Активные'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showCompletedRoutes = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showCompletedRoutes
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      foregroundColor: _showCompletedRoutes
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Завершенные'),
                  ),
                ),
              ],
            ),
          ),
          if (!_showCompletedRoutes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRouteScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Создать маршрут'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<RouteModel>>(
              stream: _routeService.getDriverRoutes(
                _currentUser!.id,
                status: _showCompletedRoutes ? RouteStatus.completed : RouteStatus.active,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка: ${snapshot.error}'),
                  );
                }

                final routes = snapshot.data ?? [];

                if (routes.isEmpty) {
                  return const Center(
                    child: Text(
                      'У вас нет маршрутов',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('${route.startPoint} → ${route.endPoint}'),
                        subtitle: Text(
                          'Отправление: ${_dateFormat.format(route.departureTime)}\n'
                          'Свободных мест: ${route.availableSeats}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.people),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetailsScreen(route: route),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 