import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/passenger/route_booking_screen.dart';
import 'package:intl/intl.dart';

class PassengerRoutesScreen extends StatefulWidget {
  const PassengerRoutesScreen({super.key});

  @override
  State<PassengerRoutesScreen> createState() => _PassengerRoutesScreenState();
}

class _PassengerRoutesScreenState extends State<PassengerRoutesScreen> {
  final _routeService = RouteService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  String? _selectedStartPoint;
  String? _selectedEndPoint;
  Set<String> _availablePoints = {};
  Set<String> _availableDestinations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _isLoading = true);
    try {
      final points = await _routeService.getUniquePoints();
      setState(() {
        _availablePoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке точек: $e')),
        );
      }
    }
  }

  Future<void> _updateDestinations(String? startPoint) async {
    if (startPoint == null) {
      setState(() {
        _selectedEndPoint = null;
        _availableDestinations = {};
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final destinations = await _routeService.getDestinationsForPoint(startPoint);
      setState(() {
        _availableDestinations = destinations;
        _selectedEndPoint = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке направлений: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск маршрутов'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStartPoint,
                    decoration: const InputDecoration(
                      labelText: 'Откуда',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Выберите пункт отправления'),
                      ),
                      ..._availablePoints.map((point) {
                        return DropdownMenuItem<String>(
                          value: point,
                          child: Text(point),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStartPoint = value);
                      _updateDestinations(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedEndPoint,
                    decoration: const InputDecoration(
                      labelText: 'Куда',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Выберите пункт назначения'),
                      ),
                      ..._availableDestinations.map((point) {
                        return DropdownMenuItem<String>(
                          value: point,
                          child: Text(point),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedEndPoint = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RouteModel>>(
              stream: _routeService.getRoutes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final routes = snapshot.data!;
                final filteredRoutes = routes.where((route) {
                  if (_selectedStartPoint == null || _selectedEndPoint == null) {
                    return true;
                  }
                  return (route.startPoint == _selectedStartPoint &&
                          route.endPoint == _selectedEndPoint) ||
                      (route.startPoint == _selectedEndPoint &&
                          route.endPoint == _selectedStartPoint);
                }).toList();

                if (filteredRoutes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Нет доступных маршрутов'),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('${route.startPoint} → ${route.endPoint}'),
                        subtitle: Text(
                          '${_dateFormat.format(route.departureTime)}\n'
                          'Свободных мест: ${route.availableSeats}',
                        ),
                        trailing: Text('${route.price} руб.'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RouteBookingScreen(route: route),
                            ),
                          );
                        },
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