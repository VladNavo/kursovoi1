import 'package:flutter/material.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:intl/intl.dart';

class TripsHistoryScreen extends StatelessWidget {
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _routeService = RouteService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  TripsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История поездок'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _authService.currentUser.then((user) {
          if (user == null) return Stream.value([]);
          return _bookingService.getUserBookings(user.id);
        }).asStream().expand((stream) => stream),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          }

          final bookings = snapshot.data ?? [];
          
          // Сортируем бронирования по дате создания (от новых к старым)
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (bookings.isEmpty) {
            return const Center(
              child: Text('У вас пока нет поездок'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return FutureBuilder<RouteModel?>(
                future: _routeService.getRoute(booking.routeId),
                builder: (context, routeSnapshot) {
                  if (!routeSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final route = routeSnapshot.data!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${route.startPoint} → ${route.endPoint}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                _getStatusText(booking.status),
                                style: TextStyle(
                                  color: _getStatusColor(booking.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Дата поездки: ${_dateFormat.format(route.departureTime)}',
                          ),
                          Text('Забронировано мест: ${booking.seats}'),
                          Text('Сумма: ${booking.totalPrice} руб.'),
                          Text('Способ оплаты: ${booking.paymentMethod}'),
                          if (booking.status == BookingStatus.confirmed)
                            Text(
                              'Начислено бонусов: ${(booking.totalPrice * 0.1).toStringAsFixed(2)} руб.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.completed:
        return 'Завершено';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }
} 