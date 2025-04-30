import 'package:flutter/material.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _routeService = RouteService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
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

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final bookingDate = DateTime(date.year, date.month, date.day);

    if (bookingDate == today) {
      return 'Сегодня';
    } else if (bookingDate == yesterday) {
      return 'Вчера';
    } else {
      return DateFormat('d MMMM', 'ru_RU').format(date);
    }
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
        title: const Text('Мои бронирования'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getUserBookings(_userId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!;
          if (bookings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('У вас нет бронирований'),
              ),
            );
          }

          // Группируем бронирования по дням
          final Map<DateTime, List<BookingModel>> groupedBookings = {};
          for (var booking in bookings) {
            final date = DateTime(
              booking.createdAt.year,
              booking.createdAt.month,
              booking.createdAt.day,
            );
            if (!groupedBookings.containsKey(date)) {
              groupedBookings[date] = [];
            }
            groupedBookings[date]!.add(booking);
          }

          // Сортируем даты в обратном порядке (новые сверху)
          final sortedDates = groupedBookings.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateBookings = groupedBookings[date]!;
              
              // Сортируем бронирования внутри дня по времени создания (новые сверху)
              dateBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _getDateHeader(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...dateBookings.map((booking) => FutureBuilder<RouteModel?>(
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
                        margin: const EdgeInsets.only(bottom: 8.0),
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
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: route.status == RouteStatus.completed
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      route.status == RouteStatus.completed ? 'Завершен' : 'Активен',
                                      style: TextStyle(
                                        color: route.status == RouteStatus.completed
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
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
                                  Text('Забронировано мест: ${booking.seats}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Итого: ${booking.totalPrice} руб.'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.payment, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Способ оплаты: ${booking.paymentMethod == 'cash' ? 'Наличные' : 'Бонусы'}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.info, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Статус: ${_getStatusText(booking.status)}',
                                    style: TextStyle(
                                      color: _getStatusColor(booking.status),
                                    ),
                                  ),
                                ],
                              ),
                              if (booking.status == BookingStatus.pending) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Отмена бронирования'),
                                          content: const Text('Вы уверены, что хотите отменить бронирование?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Нет'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Да'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true && mounted) {
                                        try {
                                          await _bookingService.updateBookingStatus(
                                            booking.id,
                                            BookingStatus.cancelled,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Бронирование отменено'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Ошибка при отмене бронирования: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Отменить бронирование'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )).toList(),
                  const SizedBox(height: 16),
                ],
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
      case BookingStatus.noShow:
        return 'Не явился';
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
      case BookingStatus.noShow:
        return Colors.red;
    }
  }
} 