import 'package:flutter/material.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:intl/intl.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _routeService = RouteService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.currentUser;
    if (user != null) {
      setState(() => _userId = user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои поездки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'История'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(_userId!, isActive: true),
          _buildBookingsList(_userId!, isActive: false),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String userId, {required bool isActive}) {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.getUserBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!;
        final filteredBookings = bookings.where((booking) {
          if (isActive) {
            return booking.status == BookingStatus.pending ||
                   booking.status == BookingStatus.confirmed;
          } else {
            return booking.status == BookingStatus.cancelled ||
                   booking.status == BookingStatus.noShow;
          }
        }).toList();

        if (filteredBookings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Нет поездок'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            final booking = filteredBookings[index];
            return FutureBuilder<RouteModel?>(
              future: _routeService.getRoute(booking.routeId),
              builder: (context, routeSnapshot) {
                if (!routeSnapshot.hasData) {
                  return const Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                    ),
                  );
                }

                final route = routeSnapshot.data;
                if (route == null) {
                  return const Card(
                    child: ListTile(
                      title: Text('Маршрут не найден'),
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${route.startPoint} → ${route.endPoint}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _buildStatusChip(booking.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Отправление: ${_dateFormat.format(route.departureTime)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Забронировано мест: ${booking.seats}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${booking.totalPrice} ₽',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        if (booking.status == BookingStatus.pending) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // TODO: Implement cancel booking
                                  },
                                  child: const Text('Отменить'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: Implement contact driver
                                  },
                                  child: const Text('Связаться с водителем'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Ожидает';
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        text = 'Подтверждено';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Отменено';
        break;
      case BookingStatus.noShow:
        color = Colors.red;
        text = 'Не явился';
        break;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
} 