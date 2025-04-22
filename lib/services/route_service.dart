import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kursovoi1/models/route_model.dart';

class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить все маршруты
  Stream<List<RouteModel>> getRoutes() {
    return _firestore
        .collection('routes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromJson(doc.data()))
            .toList());
  }

  // Получить маршруты водителя
  Stream<List<RouteModel>> getDriverRoutes(String driverId) {
    return _firestore
        .collection('routes')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromJson(doc.data()))
            .toList());
  }

  // Создать новый маршрут
  Future<void> createRoute(RouteModel route) async {
    await _firestore.collection('routes').doc(route.id).set(route.toJson());
  }

  // Обновить маршрут
  Future<void> updateRoute(RouteModel route) async {
    await _firestore.collection('routes').doc(route.id).update(route.toJson());
  }

  // Удалить маршрут
  Future<void> deleteRoute(String routeId) async {
    await _firestore.collection('routes').doc(routeId).delete();
  }

  // Добавить пассажира в маршрут
  Future<void> addPassenger(String routeId, String passengerId) async {
    await _firestore.collection('routes').doc(routeId).update({
      'passengerIds': FieldValue.arrayUnion([passengerId]),
      'availableSeats': FieldValue.increment(-1),
    });
  }

  // Удалить пассажира из маршрута
  Future<void> removePassenger(String routeId, String passengerId) async {
    await _firestore.collection('routes').doc(routeId).update({
      'passengerIds': FieldValue.arrayRemove([passengerId]),
      'availableSeats': FieldValue.increment(1),
    });
  }
} 