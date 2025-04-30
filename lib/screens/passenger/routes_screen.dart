import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/screens/passenger/route_booking_screen.dart';
import 'package:intl/intl.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/models/booking_model.dart';

enum SortOption {
  time,
  price,
  seats
}

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({Key? key}) : super(key: key);

  void showSortDialog(BuildContext context, Function(SortOption, bool) onSortChanged) {
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
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  final _bookingService = BookingService();
  final _authService = AuthService();
  String _searchQuery = '';
  String? _selectedStartPoint;
  String? _selectedEndPoint;
  SortOption _sortOption = SortOption.time;
  bool _sortAscending = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.currentUser;
    if (user != null) {
      setState(() => _userId = user.id);
    }
  }

  Future<bool> _hasExistingBooking(String routeId) async {
    if (_userId == null) return false;
    
    final bookings = await _bookingService.getUserBookings(_userId!).first;
    return bookings.any((booking) => 
      booking.routeId == routeId && 
      (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
    );
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
        title: const Text('Поиск маршрутов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => widget.showSortDialog(context, _handleSortChanged),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Откуда',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedStartPoint = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Куда',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedEndPoint = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RouteModel>>(
              stream: _routeService.getActiveRoutes(),
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
                final filteredRoutes = routes.where((route) {
                  final matchesStart = _selectedStartPoint == null ||
                      route.startPoint.toLowerCase().contains(_selectedStartPoint!.toLowerCase());
                  final matchesEnd = _selectedEndPoint == null ||
                      route.endPoint.toLowerCase().contains(_selectedEndPoint!.toLowerCase());
                  return matchesStart && matchesEnd;
                }).toList();

                final sortedRoutes = _sortRoutes(filteredRoutes);

                if (sortedRoutes.isEmpty) {
                  return const Center(
                    child: Text('Маршруты не найдены'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sortedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = sortedRoutes[index];
                    final now = DateTime.now();
                    final departureTime = route.departureTime;
                    
                    // Проверяем, совпадают ли дни
                    final sameDay = now.year == departureTime.year && 
                                  now.month == departureTime.month && 
                                  now.day == departureTime.day;
                    
                    int minutesUntilDeparture = 0;
                    if (sameDay) {
                      // Если тот же день, считаем разницу в минутах
                      minutesUntilDeparture = (departureTime.hour * 60 + departureTime.minute) - 
                                            (now.hour * 60 + now.minute);
                    } else {
                      // Если другой день, считаем как положительное время
                      minutesUntilDeparture = 1000000; // Большое число, чтобы разрешить бронирование
                    }
                    
                    print('Текущее время: ${now.hour}:${now.minute}');
                    print('Время отправления: ${departureTime.hour}:${departureTime.minute}');
                    print('Минут до отправления: $minutesUntilDeparture');
                    
                    final canBook = minutesUntilDeparture >= 10;

                    return FutureBuilder<bool>(
                      future: _hasExistingBooking(route.id),
                      builder: (context, snapshot) {
                        final hasBooking = snapshot.data ?? false;
                        final isBookable = canBook && !hasBooking;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: isBookable
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RouteBookingScreen(route: route),
                                      ),
                                    );
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${route.startPoint} → ${route.endPoint}',
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Отправление: ${_dateFormat.format(route.departureTime)}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${route.price} ₽',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          Text(
                                            'Свободно мест: ${route.availableSeats}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isBookable
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => RouteBookingScreen(route: route),
                                                ),
                                              );
                                            }
                                          : null,
                                      child: Text(hasBooking ? 'Уже забронировано' : 'Забронировать'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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