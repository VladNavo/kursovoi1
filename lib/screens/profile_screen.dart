import 'package:flutter/material.dart';
import 'package:kursovoi1/models/user_model.dart';
import 'package:kursovoi1/screens/auth/login_screen.dart';
import 'package:kursovoi1/services/auth_service.dart';
import 'package:kursovoi1/screens/driver/vehicle_edit_screen.dart';
import 'package:kursovoi1/services/vehicle_service.dart';
import 'package:kursovoi1/models/vehicle_model.dart';
import 'package:kursovoi1/services/driver_stats_service.dart';
import 'package:intl/intl.dart';
import 'package:kursovoi1/screens/admin/users_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _vehicleService = VehicleService();
  final _driverStatsService = DriverStatsService();
  final _numberFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽');
  UserModel? _currentUser;
  bool _isLoading = false;
  VehicleModel? _vehicle;
  Map<String, dynamic>? _driverStats;

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
      if (user?.role == UserRole.driver) {
        await Future.wait([
          _loadVehicle(user!.id),
          _loadDriverStats(user.id),
        ]);
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

  Future<void> _loadDriverStats(String driverId) async {
    final stats = await _driverStatsService.getDriverStats(driverId);
    if (mounted) {
      setState(() {
        _driverStats = stats;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выходе: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.driver:
        return 'Водитель';
      case UserRole.passenger:
        return 'Пассажир';
    }
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _currentUser!.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Имя',
            hintText: 'Введите ваше имя',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _authService.updateUserName(result);
        await _loadCurrentUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Имя успешно обновлено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при обновлении имени: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
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
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _currentUser!.name,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditNameDialog(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getRoleName(_currentUser!.role),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: _isLoading ? null : _handleSignOut,
                          tooltip: 'Выйти из аккаунта',
                        ),
                      ],
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Контактная информация',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(_currentUser!.email),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Телефон'),
                      subtitle: Text(_currentUser!.phone.isEmpty ? 'Не указан' : _currentUser!.phone),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentUser!.role == UserRole.passenger)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Бонусная программа',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.star),
                        title: const Text('Бонусные баллы'),
                        subtitle: Text(_currentUser!.bonusPoints.toString()),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentUser!.role == UserRole.driver) ...[
              if (_driverStats != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Статистика за ${DateTime.now().year} год',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                await _loadDriverStats(_currentUser!.id);
                                setState(() => _isLoading = false);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.directions_bus),
                          title: const Text('Всего поездок'),
                          subtitle: Text(_driverStats!['totalTrips'].toString()),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.attach_money),
                          title: const Text('Общий заработок'),
                          subtitle: Text(_numberFormat.format(_driverStats!['totalEarnings'])),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Статистика по месяцам',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...(_driverStats!['sortedMonths'] as List<String>).map((month) {
                          final stats = _driverStats!['monthlyStats'][month];
                          final [monthNum, year] = month.split('.').map(int.parse).toList();
                          final monthName = DateFormat('MMMM', 'ru_RU').format(DateTime(year, monthNum));
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monthName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Поездок: ${stats['trips']}'),
                                      Text('Заработок: ${_numberFormat.format(stats['earnings'])}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Транспорт',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VehicleEditScreen(),
                                ),
                              ).then((_) => _loadVehicle(_currentUser!.id));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_vehicle != null) ...[
                        ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text('${_vehicle!.brand} ${_vehicle!.model}'),
                          subtitle: Text('Гос. номер: ${_vehicle!.licensePlate}'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.color_lens),
                          title: const Text('Цвет'),
                          subtitle: Text(_vehicle!.color),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Год выпуска'),
                          subtitle: Text(_vehicle!.year),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Количество мест'),
                          subtitle: Text(_vehicle!.seats.toString()),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleEditScreen(vehicle: _vehicle),
                              ),
                            ).then((_) => _loadVehicle(_currentUser!.id));
                          },
                          child: const Text('Редактировать'),
                        ),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Транспорт не добавлен'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (_currentUser?.role == UserRole.admin)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Управление пользователями'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsersManagementScreen(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 