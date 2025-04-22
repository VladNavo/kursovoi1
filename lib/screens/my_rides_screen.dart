import 'package:flutter/material.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/models/ride_model.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<BookingModel> _activeBookings = [
    BookingModel(
      id: '1',
      userId: 'user1',
      ride: RideModel(
        id: '1',
        from: 'Москва',
        to: 'Санкт-Петербург',
        departureTime: DateTime.now().add(const Duration(days: 1)),
        price: 2500,
        totalSeats: 4,
        availableSeats: 3,
        driverId: 'driver1',
        carModel: 'Toyota Camry',
        carNumber: 'A123BC777',
      ),
      bookingDate: DateTime.now(),
      status: BookingStatus.confirmed,
      seats: 1,
      totalPrice: 2500,
    ),
    BookingModel(
      id: '2',
      userId: 'user1',
      ride: RideModel(
        id: '2',
        from: 'Москва',
        to: 'Казань',
        departureTime: DateTime.now().add(const Duration(days: 3)),
        price: 2000,
        totalSeats: 3,
        availableSeats: 2,
        driverId: 'driver2',
        carModel: 'Kia K5',
        carNumber: 'B456DE777',
      ),
      bookingDate: DateTime.now(),
      status: BookingStatus.pending,
      seats: 2,
      totalPrice: 4000,
    ),
  ];

  final List<BookingModel> _historyBookings = [
    BookingModel(
      id: '3',
      userId: 'user1',
      ride: RideModel(
        id: '3',
        from: 'Москва',
        to: 'Нижний Новгород',
        departureTime: DateTime.now().subtract(const Duration(days: 5)),
        price: 1800,
        totalSeats: 3,
        availableSeats: 0,
        driverId: 'driver3',
        carModel: 'Hyundai Solaris',
        carNumber: 'C789EF777',
      ),
      bookingDate: DateTime.now().subtract(const Duration(days: 6)),
      status: BookingStatus.completed,
      seats: 1,
      totalPrice: 1800,
    ),
    BookingModel(
      id: '4',
      userId: 'user1',
      ride: RideModel(
        id: '4',
        from: 'Москва',
        to: 'Тула',
        departureTime: DateTime.now().subtract(const Duration(days: 10)),
        price: 1200,
        totalSeats: 3,
        availableSeats: 1,
        driverId: 'driver4',
        carModel: 'Lada Vesta',
        carNumber: 'D012GH777',
      ),
      bookingDate: DateTime.now().subtract(const Duration(days: 11)),
      status: BookingStatus.cancelled,
      seats: 1,
      totalPrice: 1200,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildBookingsList(_activeBookings),
          _buildBookingsList(_historyBookings),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('Нет поездок'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
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
                        '${booking.ride.from} → ${booking.ride.to}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _buildStatusChip(booking.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Отправление: ${booking.ride.departureTime.toString().split('.')[0]}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Автомобиль: ${booking.ride.carModel} (${booking.ride.carNumber})',
                  style: Theme.of(context).textTheme.bodyMedium,
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
      case BookingStatus.completed:
        color = Colors.blue;
        text = 'Завершено';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Отменено';
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