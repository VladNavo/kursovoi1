import 'package:flutter/material.dart';
import 'package:kursovoi1/models/ride_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<RideModel> _rides = [
    RideModel(
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
    RideModel(
      id: '2',
      from: 'Москва',
      to: 'Казань',
      departureTime: DateTime.now().add(const Duration(days: 2)),
      price: 2000,
      totalSeats: 3,
      availableSeats: 2,
      driverId: 'driver2',
      carModel: 'Kia K5',
      carNumber: 'B456DE777',
    ),
  ];

  final List<String> _popularCities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Нижний Новгород',
    'Новосибирск',
    'Екатеринбург',
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _refreshRides() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Заменить на реальный запрос к Firestore
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _rides = [
          RideModel(
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
          RideModel(
            id: '2',
            from: 'Москва',
            to: 'Казань',
            departureTime: DateTime.now().add(const Duration(days: 2)),
            price: 2000,
            totalSeats: 3,
            availableSeats: 2,
            driverId: 'driver2',
            carModel: 'Kia K5',
            carNumber: 'B456DE777',
          ),
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно обновлены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении: $e')),
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

  void _showRideDetails(RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ride.from} → ${ride.to}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Отправление:', ride.departureTime.toString().split('.')[0]),
              const SizedBox(height: 8),
              _buildDetailRow('Автомобиль:', '${ride.carModel} (${ride.carNumber})'),
              const SizedBox(height: 8),
              _buildDetailRow('Свободно мест:', '${ride.availableSeats} из ${ride.totalSeats}'),
              const SizedBox(height: 8),
              _buildDetailRow('Цена:', '${ride.price} BYN'),
              const SizedBox(height: 16),
              const Text(
                'Дополнительная информация:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Время в пути: ~8 часов'),
              const Text('• Комфортабельный автомобиль'),
              const Text('• Кондиционер'),
              const Text('• Wi-Fi'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные поездки'),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshRides,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _popularCities.where((city) =>
                          city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _fromController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Откуда',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите город отправления';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _popularCities.where((city) =>
                          city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _toController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Куда',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите город прибытия';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата поездки',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Implement search
                        }
                      },
                      child: const Text('Найти поездки'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final ride = _rides[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.from} → ${ride.to}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Отправление: ${ride.departureTime.toString().split('.')[0]}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Автомобиль: ${ride.carModel} (${ride.carNumber})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Свободно мест: ${ride.availableSeats} из ${ride.totalSeats}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showRideDetails(ride),
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Подробнее'),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${ride.price} BYN',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                if (ride.availableSeats > 0)
                                  ElevatedButton(
                                    onPressed: () {
                                      // TODO: Implement booking
                                    },
                                    child: const Text('Забронировать'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new ride creation
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 