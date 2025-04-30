import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kursovoi1/models/route_model.dart';
import 'package:kursovoi1/models/user_model.dart';

class BonusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Начислить бонусы после завершения поездки
  Future<void> addBonusPoints(String userId, RouteModel route) async {
    final bonusPoints = (route.price * 0.1).round(); // 10% от стоимости поездки
    
    await _firestore.collection('users').doc(userId).update({
      'bonusPoints': FieldValue.increment(bonusPoints),
    });
  }

  // Использовать бонусные баллы для оплаты
  Future<bool> useBonusPoints(String userId, double amount) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final user = UserModel.fromMap({...userDoc.data()!, 'id': userDoc.id});
    
    if (user.bonusPoints < amount) {
      return false; // Недостаточно бонусов
    }

    await _firestore.collection('users').doc(userId).update({
      'bonusPoints': FieldValue.increment(-amount),
    });

    return true;
  }

  // Получить текущий баланс бонусов
  Future<int> getBonusBalance(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return (userDoc.data()?['bonusPoints'] as int?) ?? 0;
  }
} 