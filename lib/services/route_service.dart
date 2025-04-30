import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kursovoi1/models/route_model.dart';

class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'routes';

  // Очистить все маршруты
  Future<void> clearAllRoutes() async {
    final snapshot = await _firestore.collection(_collection).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Получить все маршруты
  Stream<List<RouteModel>> getRoutes() {
    print('RouteService: запрос маршрутов');
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: RouteStatus.active.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
      print('RouteService: получено ${snapshot.docs.length} маршрутов');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final departureTime = (data['departureTime'] as Timestamp).toDate();
        final now = DateTime.now();
        final timeUntilDeparture = departureTime.difference(now);
        
        print('RouteService: расчет времени до отправления:');
        print('Время отправления: $departureTime');
        print('Текущее время: $now');
        print('Разница в минутах: ${timeUntilDeparture.inMinutes}');
        print('Разница в часах: ${timeUntilDeparture.inHours}');
        
        print('RouteService: маршрут ${doc.id} - ${data['startPoint']} → ${data['endPoint']}');
        return RouteModel.fromMap({
          ...data,
          'id': doc.id,
          'timeUntilDeparture': timeUntilDeparture,
        });
      }).toList();
    });
  }

  // Получить все маршруты (включая завершенные)
  Stream<List<RouteModel>> getAllRoutes() {
    print('RouteService: запрос всех маршрутов');
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      print('RouteService: получено ${snapshot.docs.length} маршрутов');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('RouteService: маршрут ${doc.id} - ${data['startPoint']} → ${data['endPoint']}');
        return RouteModel.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  Future<RouteModel?> getRoute(String routeId) async {
    final doc = await _firestore.collection(_collection).doc(routeId).get();
    if (!doc.exists) return null;
    return RouteModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  // Получить маршруты водителя
  Stream<List<RouteModel>> getDriverRoutes(String driverId, {RouteStatus? status}) {
    print('RouteService: запрос маршрутов водителя $driverId');
    var query = _firestore
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('departureTime', descending: false);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    return query.snapshots().map((snapshot) {
      print('RouteService: получено ${snapshot.docs.length} маршрутов водителя');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('RouteService: маршрут ${doc.id} - ${data['startPoint']} → ${data['endPoint']}, дата: ${data['departureTime']}');
        return RouteModel.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  // Создать новый маршрут
  Future<void> createRoute(RouteModel route) async {
    await _firestore.collection(_collection).add(route.toMap());
  }

  // Обновить маршрут
  Future<void> updateRoute(RouteModel route) async {
    await _firestore.collection(_collection).doc(route.id).update(route.toMap());
  }

  // Удалить маршрут
  Future<void> deleteRoute(String routeId) async {
    await _firestore.collection(_collection).doc(routeId).delete();
  }

  // Добавить пассажира в маршрут
  Future<void> addPassenger(String routeId, String passengerId) async {
    await _firestore.collection(_collection).doc(routeId).update({
      'passengerIds': FieldValue.arrayUnion([passengerId]),
      'availableSeats': FieldValue.increment(-1),
    });
  }

  // Удалить пассажира из маршрута
  Future<void> removePassenger(String routeId, String passengerId) async {
    await _firestore.collection(_collection).doc(routeId).update({
      'passengerIds': FieldValue.arrayRemove([passengerId]),
      'availableSeats': FieldValue.increment(1),
    });
  }

  Future<Set<String>> getUniquePoints() async {
    print('RouteService: запрос уникальных точек');
    final snapshot = await _firestore.collection(_collection).get();
    final points = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      points.add(data['startPoint'] as String);
      points.add(data['endPoint'] as String);
    }
    print('RouteService: найдено ${points.length} уникальных точек');
    return points;
  }

  Future<Set<String>> getDestinationsForPoint(String point) async {
    final snapshot = await _firestore.collection(_collection).get();
    final destinations = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['startPoint'] == point) {
        destinations.add(data['endPoint'] as String);
      } else if (data['endPoint'] == point) {
        destinations.add(data['startPoint'] as String);
      }
    }
    return destinations;
  }

  // Обновить количество свободных мест
  Future<void> updateAvailableSeats(String routeId, int seats) async {
    await _firestore.collection(_collection).doc(routeId).update({
      'availableSeats': FieldValue.increment(-seats),
    });
  }

  // Получить информацию о пассажирах маршрута
  Stream<List<Map<String, dynamic>>> getRoutePassengers(String routeId) {
    return _firestore
        .collection('bookings')
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .asyncMap((snapshot) async {
      final passengers = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final booking = doc.data();
        final userDoc = await _firestore
            .collection('users')
            .doc(booking['userId'])
            .get();
        if (userDoc.exists) {
          passengers.add({
            'booking': booking,
            'user': userDoc.data(),
          });
        }
      }
      return passengers;
    });
  }

  // Подтвердить пассажира
  Future<void> confirmPassenger(String routeId, String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'isConfirmed': true,
    });
  }

  // Завершить маршрут
  Future<void> completeRoute(String routeId) async {
    await _firestore.collection(_collection).doc(routeId).update({
      'status': RouteStatus.completed.toString().split('.').last,
    });
  }

  Stream<List<RouteModel>> getActiveRoutes() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RouteModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }
} 