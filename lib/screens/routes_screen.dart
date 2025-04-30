import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/passenger/route_details_screen.dart';

enum SortOption {
  time,
  price,
  seats
}

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({Key? key}) : super(key: key);

  static void showSortDialog(BuildContext context, Function(SortOption, bool) onSortChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Сортировка'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('По времени'),
                onTap: () {
                  onSortChanged(SortOption.time, true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('По стоимости'),
                onTap: () {
                  onSortChanged(SortOption.price, true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_seat),
                title: const Text('По свободным местам'),
                onTap: () {
                  onSortChanged(SortOption.seats, true);
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
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final _routeService = RouteService();
  SortOption _sortOption = SortOption.time;
  bool _sortAscending = true;

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

  void _handleSortChanged(SortOption option, bool ascending) {
    setState(() {
      if (_sortOption == option) {
        _sortAscending = !_sortAscending;
      } else {
        _sortOption = option;
        _sortAscending = ascending;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные маршруты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => RoutesScreen.showSortDialog(context, _handleSortChanged),
          ),
        ],
      ),
      body: StreamBuilder<List<RouteModel>>(
        stream: _routeService.getRoutes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final routes = snapshot.data ?? [];
          final sortedRoutes = _sortRoutes(routes);

          if (sortedRoutes.isEmpty) {
            return const Center(
              child: Text('Нет доступных маршрутов'),
            );
          }

          return ListView.builder(
            itemCount: sortedRoutes.length,
            itemBuilder: (context, index) {
              final route = sortedRoutes[index];
              final timeUntilDeparture = route.timeUntilDeparture;
              final canBook = timeUntilDeparture != null && 
                             timeUntilDeparture.inMinutes > 10;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${route.startPoint} → ${route.endPoint}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Отправление: ${route.departureTime.toString()}'),
                      Text('Свободных мест: ${route.availableSeats}'),
                      Text('Цена: ${route.price} ₽'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: canBook
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetailsScreen(route: route),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Забронировать'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 