import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../services/auth_service.dart';

class VehicleEditScreen extends StatefulWidget {
  final VehicleModel? vehicle;

  const VehicleEditScreen({Key? key, this.vehicle}) : super(key: key);

  @override
  _VehicleEditScreenState createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  final _authService = AuthService();
  bool _isLoading = false;

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _colorController;
  late TextEditingController _licensePlateController;
  late TextEditingController _yearController;
  late TextEditingController _seatsController;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _colorController = TextEditingController(text: widget.vehicle?.color ?? '');
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _yearController = TextEditingController(text: widget.vehicle?.year ?? '');
    _seatsController = TextEditingController(text: widget.vehicle?.seats.toString() ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.currentUser;
      if (currentUser == null) throw Exception('Пользователь не авторизован');

      final vehicle = VehicleModel(
        id: widget.vehicle?.id ?? '',
        driverId: currentUser.id,
        brand: _brandController.text,
        model: _modelController.text,
        color: _colorController.text,
        licensePlate: _licensePlateController.text,
        year: _yearController.text,
        seats: int.parse(_seatsController.text),
      );

      if (widget.vehicle == null) {
        await _vehicleService.addVehicle(vehicle);
      } else {
        await _vehicleService.updateVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Информация о транспорте сохранена')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Добавить транспорт' : 'Редактировать транспорт'),
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
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: 'Марка'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите марку';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Модель'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите модель';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(labelText: 'Цвет'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите цвет';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(labelText: 'Гос. номер'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите гос. номер';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(labelText: 'Год выпуска'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите год выпуска';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seatsController,
                      decoration: const InputDecoration(labelText: 'Количество мест'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите количество мест';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Введите корректное число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveVehicle,
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 