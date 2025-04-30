import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/services/vehicle_service.dart';
import 'package:kursovoi1/models/vehicle_model.dart';
import 'package:intl/intl.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailsScreen({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = false;
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  VehicleModel? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    final vehicle = await _vehicleService.getVehicleByDriverId(widget.route.driverId);
    if (mounted) {
      setState(() {
        _vehicle = vehicle;
      });
    }
  }

  Future<void> _bookRoute() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _bookingService.createBooking(
        routeId: widget.route.id,
        passengerId: user.id,
        driverId: widget.route.driverId,
        seats: 1,
        totalPrice: widget.route.price,
        paymentMethod: 'cash',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка на бронирование отправлена'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.route.startPoint} → ${widget.route.endPoint}'),
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
                    if (widget.route.timeUntilDeparture != null)
                      Text(
                        'До отправления: ${widget.route.timeUntilDeparture!.inHours}ч ${widget.route.timeUntilDeparture!.inMinutes % 60}м',
                      ),
                  ],
                ),
              ),
            ),
            if (_vehicle != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация о транспорте',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Марка и модель: ${_vehicle!.brand} ${_vehicle!.model}'),
                      const SizedBox(height: 4),
                      Text('Цвет: ${_vehicle!.color}'),
                      const SizedBox(height: 4),
                      Text('Гос. номер: ${_vehicle!.licensePlate}'),
                      const SizedBox(height: 4),
                      Text('Год выпуска: ${_vehicle!.year}'),
                      const SizedBox(height: 4),
                      Text('Количество мест: ${_vehicle!.seats}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (widget.route.availableSeats > 0)
              ElevatedButton(
                onPressed: _isLoading ? null : _bookRoute,
                child: const Text('Забронировать место'),
              ),
          ],
        ),
      ),
    );
  }
} 