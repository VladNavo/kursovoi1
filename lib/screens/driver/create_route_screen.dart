import 'package:flutter/material.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/services/route_service.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:kursovoi1/services/vehicle_service.dart';
import 'package:kursovoi1/models/vehicle_model.dart';
import 'package:kursovoi1/screens/driver/vehicle_edit_screen.dart';
import 'package:uuid/uuid.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeService = RouteService();
  final _authService = AuthService();
  final _vehicleService = VehicleService();
  final _uuid = const Uuid();
  UserModel? _currentUser;
  bool _isLoading = false;
  VehicleModel? _vehicle;

  // Контроллеры для полей формы
  final _startPointController = TextEditingController(text: 'Автовокзал');
  final _endPointController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  DateTime _departureTime = DateTime.now();
  TimeOfDay _departureTimeOfDay = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        _loadVehicle(user.id);
      }
    }
  }

  Future<void> _loadVehicle(String driverId) async {
    final vehicle = await _vehicleService.getVehicleByDriverId(driverId);
    if (mounted) {
      setState(() {
        _vehicle = vehicle;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _departureTime) {
      setState(() {
        _departureTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _departureTimeOfDay.hour,
          _departureTimeOfDay.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _departureTimeOfDay,
    );
    if (picked != null && picked != _departureTimeOfDay) {
      setState(() {
        _departureTimeOfDay = picked;
        _departureTime = DateTime(
          _departureTime.year,
          _departureTime.month,
          _departureTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для создания маршрута необходимо добавить транспорт в профиле'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Создание маршрута:');
      print('Время отправления: $_departureTime');
      print('Текущее время: ${DateTime.now()}');
      
      // Убедимся, что время сохранено в UTC
      final departureTimeUtc = _departureTime.toUtc();
      print('Время отправления UTC: $departureTimeUtc');
      
      // Формируем строки с автовокзалом в скобках
      final startPoint = '${_startPointController.text} (Автовокзал)';
      final endPoint = '${_endPointController.text} (Автовокзал)';
      
      final route = RouteModel(
        id: '',
        startPoint: startPoint,
        endPoint: endPoint,
        departureTime: departureTimeUtc,
        availableSeats: _vehicle!.seats,
        price: double.parse(_priceController.text),
        driverId: _currentUser!.id,
        status: RouteStatus.active,
      );

      await _routeService.createRoute(route);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Маршрут успешно создан')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании маршрута: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _startPointController.dispose();
    _endPointController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Создание маршрута'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Для создания маршрута необходимо добавить транспорт',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleEditScreen(),
                    ),
                  ).then((_) => _loadVehicle(_currentUser!.id));
                },
                child: const Text('Добавить транспорт'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание маршрута'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _startPointController,
                      decoration: const InputDecoration(
                        labelText: 'Место отправления',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите место отправления';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _endPointController,
                      decoration: const InputDecoration(
                        labelText: 'Место прибытия',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите место прибытия';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${_departureTime.day}.${_departureTime.month}.${_departureTime.year}',
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _selectTime(context),
                            icon: const Icon(Icons.access_time),
                            label: Text(_departureTimeOfDay.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена за место (руб.)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите цену';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Введите корректную цену';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: const Text('Создать маршрут'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 