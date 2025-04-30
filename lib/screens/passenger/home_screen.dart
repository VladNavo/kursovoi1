import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/passenger/route_details_screen.dart';
import 'package:kursovoi1/screens/passenger/search_routes_screen.dart';
import 'package:kursovoi1/screens/profile_screen.dart';
import 'package:kursovoi1/screens/passenger/my_bookings_screen.dart';
import 'package:intl/intl.dart';

enum SortOption {
  time,
  price,
  seats
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _routeService = RouteService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  String? _selectedStartPoint;
  String? _selectedEndPoint;
  Set<String> _startPoints = {};
  Set<String> _endPoints = {};
  SortOption _sortOption = SortOption.time;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await _routeService.getUniquePoints();
    setState(() {
      _startPoints = points;
    });
  }

  Future<void> _loadDestinations(String point) async {
    final destinations = await _routeService.getDestinationsForPoint(point);
    setState(() {
      _endPoints = destinations;
    });
  }

  List<RouteModel> _sortRoutes(List<RouteModel> routes) {
    final sortedRoutes = List<RouteModel>.from(routes);
    
    switch (_sortOption) {
      case SortOption.time:
        sortedRoutes.sort((a, b) => _sortAscending
            ? a.departureTime.compareTo(b.departureTime)
            : b.departureTime.compareTo(a.departureTime));
        break;
      case SortOption.price:
        sortedRoutes.sort((a, b) => _sortAscending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case SortOption.seats:
        sortedRoutes.sort((a, b) => _sortAscending
            ? a.availableSeats.compareTo(b.availableSeats)
            : b.availableSeats.compareTo(a.availableSeats));
        break;
    }
    
    return sortedRoutes;
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Сортировка'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: _sortOption == SortOption.time
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: const Text('По времени'),
                trailing: _sortOption == SortOption.time
                    ? Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.time) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.time;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: _sortOption == SortOption.price
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: const Text('По стоимости'),
                trailing: _sortOption == SortOption.price
                    ? Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.price) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.price;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.event_seat,
                  color: _sortOption == SortOption.seats
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: const Text('По свободным местам'),
                trailing: _sortOption == SortOption.seats
                    ? Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.seats) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.seats;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные маршруты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
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
                      ..._startPoints.map((point) {
                        return DropdownMenuItem<String>(
                          value: point,
                          child: Text(point),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStartPoint = value);
                      if (value != null) {
                        _loadDestinations(value);
                      }
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
                      ..._endPoints.map((point) {
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

                final sortedRoutes = _sortRoutes(filteredRoutes);

                if (sortedRoutes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Нет доступных маршрутов',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8.0),
                  itemCount: sortedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = sortedRoutes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          '${route.startPoint} → ${route.endPoint}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Отправление: ${_dateFormat.format(route.departureTime)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Свободных мест: ${route.availableSeats}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${route.price} ₽',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RouteDetailsScreen(route: route),
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