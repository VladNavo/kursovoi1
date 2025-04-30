import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kursovoi1/models/route_model.dart';

class DriverStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    
    // Получаем только завершенные маршруты
    final routesSnapshot = await _firestore
        .collection('routes')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: RouteStatus.completed.toString().split('.').last)
        .where('departureTime', isGreaterThanOrEqualTo: startOfYear)
        .get();

    final routes = routesSnapshot.docs
        .map((doc) => RouteModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    // Получаем информацию о пассажирах для каждого маршрута
    final monthlyStats = <String, Map<String, dynamic>>{};
    double totalEarnings = 0;
    int totalPassengers = 0;

    for (var route in routes) {
      // Получаем подтвержденные бронирования для маршрута
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('routeId', isEqualTo: route.id)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final confirmedBookings = bookingsSnapshot.docs;
      final passengersCount = confirmedBookings.fold<int>(
        0,
        (sum, booking) => sum + (booking.data()['seats'] as int),
      );

      final month = '${route.departureTime.month}.${route.departureTime.year}';
      if (!monthlyStats.containsKey(month)) {
        monthlyStats[month] = {
          'trips': 0,
          'passengers': 0,
          'earnings': 0.0,
        };
      }
      
      final routeEarnings = route.price * passengersCount;
      monthlyStats[month]!['trips']++;
      monthlyStats[month]!['passengers'] += passengersCount;
      monthlyStats[month]!['earnings'] += routeEarnings;
      
      totalEarnings += routeEarnings;
      totalPassengers += passengersCount;
    }

    // Сортируем по месяцам
    final sortedMonths = monthlyStats.keys.toList()
      ..sort((a, b) {
        final [aMonth, aYear] = a.split('.').map(int.parse).toList();
        final [bMonth, bYear] = b.split('.').map(int.parse).toList();
        if (aYear != bYear) return aYear.compareTo(bYear);
        return aMonth.compareTo(bMonth);
      });

    return {
      'monthlyStats': monthlyStats,
      'sortedMonths': sortedMonths,
      'totalTrips': routes.length,
      'totalPassengers': totalPassengers,
      'totalEarnings': totalEarnings,
    };
  }
} 