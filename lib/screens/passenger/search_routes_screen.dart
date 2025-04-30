import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/passenger/route_booking_screen.dart';
import 'package:intl/intl.dart';

class SearchRoutesScreen extends StatefulWidget {
  final String startPoint;
  final String endPoint;

  const SearchRoutesScreen({
    super.key,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  State<SearchRoutesScreen> createState() => _SearchRoutesScreenState();
}

class _SearchRoutesScreenState extends State<SearchRoutesScreen> {
  final _routeService = RouteService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          final filteredRoutes = routes.where((route) {
            return (route.startPoint == widget.startPoint &&
                    route.endPoint == widget.endPoint) ||
                (route.startPoint == widget.endPoint &&
                    route.endPoint == widget.startPoint);
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
            padding: const EdgeInsets.all(16),
            itemCount: filteredRoutes.length,
            itemBuilder: (context, index) {
              final route = filteredRoutes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteBookingScreen(route: route),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route.startPoint} → ${route.endPoint}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(_dateFormat.format(route.departureTime)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16),
                            const SizedBox(width: 8),
                            Text('${route.availableSeats} из ${route.availableSeats + route.passengerIds.length} мест свободно'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16),
                            const SizedBox(width: 8),
                            Text('${route.price} руб. за место'),
                          ],
                        ),
                      ],
                    ),
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