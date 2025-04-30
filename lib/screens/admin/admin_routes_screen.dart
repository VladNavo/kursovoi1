import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/admin/create_route_screen.dart';
import 'package:kursovoi1/services/user_service.dart';

class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final _routeService = RouteService();
  final _userService = UserService();

  Future<void> _clearAllRoutes() async {
    try {
      await _routeService.clearAllRoutes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Все маршруты удалены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении маршрутов: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Маршруты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить все маршруты?'),
                  content: const Text('Вы уверены, что хотите удалить все маршруты? Это действие нельзя отменить.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearAllRoutes();
                        Navigator.pop(context);
                      },
                      child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<RouteModel>>(
        stream: _routeService.getRoutes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final routes = snapshot.data!;
          if (routes.isEmpty) {
            return const Center(
              child: Text('Нет доступных маршрутов'),
            );
          }

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text('${route.startPoint} → ${route.endPoint}'),
                  subtitle: Text('Водитель ID: ${route.driverId}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Время отправления: ${route.departureTime.toString()}'),
                          Text('Свободных мест: ${route.availableSeats}'),
                          Text('Цена: ${route.price} руб.'),
                          Text('Статус: ${_getStatusText(route.status)}'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Удалить маршрут?'),
                                      content: const Text('Вы уверены, что хотите удалить этот маршрут?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _routeService.deleteRoute(route.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Удалить'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Удалить'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusText(RouteStatus status) {
    switch (status) {
      case RouteStatus.active:
        return 'Активен';
      case RouteStatus.completed:
        return 'Завершен';
      case RouteStatus.cancelled:
        return 'Отменен';
    }
  }
} 