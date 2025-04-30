import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicles';

  Future<VehicleModel?> getVehicleByDriverId(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('driverId', isEqualTo: driverId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VehicleModel.fromMap({
        ...querySnapshot.docs.first.data(),
        'id': querySnapshot.docs.first.id,
      });
    } catch (e) {
      print('Ошибка при получении транспорта: $e');
      return null;
    }
  }

  Future<void> addVehicle(VehicleModel vehicle) async {
    try {
      await _firestore.collection(_collection).add(vehicle.toMap());
    } catch (e) {
      print('Ошибка при добавлении транспорта: $e');
      rethrow;
    }
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(vehicle.id)
          .update(vehicle.toMap());
    } catch (e) {
      print('Ошибка при обновлении транспорта: $e');
      rethrow;
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection(_collection).doc(vehicleId).delete();
    } catch (e) {
      print('Ошибка при удалении транспорта: $e');
      rethrow;
    }
  }
} 