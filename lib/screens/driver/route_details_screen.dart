import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/services/bonus_service.dart';
import 'package:kursovoi1/services/user_service.dart';
import 'package:intl/intl.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailsScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final _routeService = RouteService();
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _bonusService = BonusService();
  final _userService = UserService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  bool _isLoading = false;

  Future<void> _confirmPassengerArrival(String bookingId, String userId) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, BookingStatus.confirmed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Прибытие пассажира подтверждено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId, int seats) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, BookingStatus.cancelled);
      // Уменьшаем количество мест только при отмене
      await _routeService.updateAvailableSeats(widget.route.id, -seats);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Бронирование отменено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _completeRoute() async {
    // Показываем диалог подтверждения
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить маршрут?'),
        content: const Text(
          'Вы уверены, что хотите завершить маршрут? Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (shouldComplete != true) return;

    setState(() => _isLoading = true);
    try {
      // Получаем все подтвержденные бронирования
      final bookings = await _bookingService.getRouteBookings(widget.route.id).first;
      final confirmedBookings = bookings.where((b) => b.status == BookingStatus.confirmed);

      // Начисляем бонусы всем пассажирам
      for (final booking in confirmedBookings) {
        await _bonusService.addBonusPoints(booking.userId, widget.route);
      }

      // Завершаем маршрут
      await _routeService.completeRoute(widget.route.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Маршрут завершен, бонусы начислены')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.route.startPoint} → ${widget.route.endPoint}'),
        actions: [
          if (widget.route.status == RouteStatus.active)
            IconButton(
              onPressed: _isLoading ? null : _completeRoute,
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Завершить маршрут',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.route.startPoint} → ${widget.route.endPoint}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Дата и время: ${_dateFormat.format(widget.route.departureTime)}',
                    ),
                    const SizedBox(height: 8),
                    Text('Свободных мест: ${widget.route.availableSeats}'),
                    const SizedBox(height: 8),
                    Text('Цена за место: ${widget.route.price} руб.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Забронированные места',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<BookingModel>>(
              stream: _bookingService.getRouteBookings(widget.route.id),
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
                    child: Text('Нет забронированных мест'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return FutureBuilder<UserModel?>(
                      future: _userService.getUser(booking.userId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final user = userSnapshot.data!;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                              child: user.photoURL == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Забронировано мест: ${booking.seats}'),
                                Text('Статус: ${_getStatusText(booking.status)}'),
                                Text('Способ оплаты: ${booking.paymentMethod}'),
                              ],
                            ),
                            trailing: booking.status == BookingStatus.pending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _confirmPassengerArrival(booking.id, booking.userId),
                                        child: const Text('Подтвердить'),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _cancelBooking(booking.id, booking.seats),
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                      ),
                                    ],
                                  )
                                : booking.status == BookingStatus.confirmed
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if (widget.route.status == RouteStatus.active)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Завершение маршрута',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'После завершения маршрута всем подтвержденным пассажирам будут начислены бонусы.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'Завершить маршрут',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 