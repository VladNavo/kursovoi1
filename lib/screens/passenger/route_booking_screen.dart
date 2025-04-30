import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:kursovoi1/services/booking_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/services/bonus_service.dart';
import 'package:kursovoi1/services/vehicle_service.dart';
import 'package:kursovoi1/models/vehicle_model.dart';

enum PaymentMethod {
  cash,
  bonus
}

class RouteBookingScreen extends StatefulWidget {
  final RouteModel route;

  const RouteBookingScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteBookingScreen> createState() => _RouteBookingScreenState();
}

class _RouteBookingScreenState extends State<RouteBookingScreen> {
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  final _routeService = RouteService();
  final _bonusService = BonusService();
  final _vehicleService = VehicleService();
  bool _isLoading = false;
  int _selectedSeats = 1;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  double _bonusBalance = 0.0;
  VehicleModel? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadBonusBalance();
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

  Future<void> _loadBonusBalance() async {
    final user = await _authService.currentUser;
    if (user != null) {
      final balance = await _bonusService.getBonusBalance(user.id);
      setState(() {
        _bonusBalance = balance.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.route.price * _selectedSeats;
    final canUseBonus = _bonusBalance >= totalPrice;
    final missingBonus = totalPrice - _bonusBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            'Отправление: ${_dateFormat.format(widget.route.departureTime)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Свободно мест: ${widget.route.availableSeats}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Цена за место: ${widget.route.price} руб.',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                  const SizedBox(height: 24),
                  Text(
                    'Количество мест',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _selectedSeats > 1
                            ? () => setState(() => _selectedSeats--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        _selectedSeats.toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: _selectedSeats < widget.route.availableSeats
                            ? () => setState(() => _selectedSeats++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Способ оплаты',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          title: const Text('Наличные'),
                          value: PaymentMethod.cash,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          title: const Text('Бонусы'),
                          value: PaymentMethod.bonus,
                          groupValue: _selectedPaymentMethod,
                          onChanged: canUseBonus
                              ? (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedPaymentMethod == PaymentMethod.bonus && !canUseBonus)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Недостаточно бонусов. Не хватает: ${missingBonus.toStringAsFixed(2)} руб.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Итого к оплате: ${totalPrice.toStringAsFixed(2)} руб.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ||
                              (_selectedPaymentMethod == PaymentMethod.bonus && !canUseBonus)
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final user = await _authService.currentUser;
                                if (user == null) {
                                  throw Exception('Пользователь не авторизован');
                                }

                                await _bookingService.createBooking(
                                  routeId: widget.route.id,
                                  passengerId: user.id,
                                  driverId: widget.route.driverId,
                                  seats: _selectedSeats,
                                  totalPrice: totalPrice,
                                  paymentMethod: _selectedPaymentMethod == PaymentMethod.cash
                                      ? 'cash'
                                      : 'bonus',
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
                                  String errorMessage = 'Ошибка при бронировании';
                                  if (e.toString().contains('Недостаточно свободных мест')) {
                                    errorMessage = 'К сожалению, выбранное количество мест больше не доступно. Пожалуйста, обновите страницу и попробуйте снова.';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      child: const Text('Подтвердить бронирование'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 