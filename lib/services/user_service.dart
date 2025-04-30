import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kursovoi1/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap({...doc.data()!, 'id': doc.id});
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.id).update(user.toMap());
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Ошибка при удалении пользователя: $e');
    }
  }
} 