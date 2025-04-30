import 'package:flutter/material.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/screens/passenger/booking_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:kursovoi1/services/auth_service.dart';

class PassengerBookingsScreen extends StatefulWidget {
  const PassengerBookingsScreen({Key? key}) : super(key: key);

  @override
  State<PassengerBookingsScreen> createState() => _PassengerBookingsScreenState();
}

class _PassengerBookingsScreenState extends State<PassengerBookingsScreen> {
  final _authService = AuthService();
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
    final bookingService = BookingService();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои бронирования'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getUserBookings(_userId),
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
          
          if (bookings.isEmpty) {
            return const Center(
              child: Text('У вас пока нет бронирований'),
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
            padding: const EdgeInsets.all(16.0),
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
                  ...dateBookings.map((booking) => Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(
                        '${booking.startPoint} → ${booking.endPoint}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Дата: ${dateFormat.format(booking.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Статус: ${_getStatusText(booking.status)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(booking.status),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(booking: booking),
                          ),
                        );
                      },
                    ),
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
      case BookingStatus.completed:
        return 'Завершено';
      case BookingStatus.cancelled:
        return 'Отменено';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
} 