import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kursovoi1/models/booking_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  Stream<List<BookingModel>> getRouteBookings(String routeId) {
    return _firestore
        .collection(_collection)
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': status.toString().split('.').last,
      });

      // Если бронирование отменено, возвращаем места
      if (status == BookingStatus.cancelled) {
        final bookingDoc = await _firestore.collection(_collection).doc(bookingId).get();
        final booking = BookingModel.fromMap({...bookingDoc.data()!, 'id': bookingDoc.id});
        
        await _firestore.collection('routes').doc(booking.routeId).update({
          'availableSeats': FieldValue.increment(booking.seats),
        });
      }
    } catch (e) {
      print('Ошибка при обновлении статуса бронирования: $e');
      rethrow;
    }
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  Future<BookingModel> createBooking({
    required String routeId,
    required String passengerId,
    required String driverId,
    required int seats,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    final docRef = _firestore.collection('bookings').doc();
    final booking = BookingModel(
      id: docRef.id,
      routeId: routeId,
      userId: passengerId,
      driverId: driverId,
      seats: seats,
      totalPrice: totalPrice,
      status: BookingStatus.pending,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    // Создаем транзакцию для атомарного обновления
    await _firestore.runTransaction((transaction) async {
      // Получаем текущее количество свободных мест
      final routeDoc = await transaction.get(_firestore.collection('routes').doc(routeId));
      final currentSeats = routeDoc.data()?['availableSeats'] as int? ?? 0;

      // Проверяем, достаточно ли мест
      if (currentSeats < seats) {
        throw Exception('Недостаточно свободных мест');
      }

      // Уменьшаем количество свободных мест
      transaction.update(
        _firestore.collection('routes').doc(routeId),
        {'availableSeats': currentSeats - seats},
      );

      // Создаем бронирование
      transaction.set(docRef, booking.toMap());
    });

    return booking;
  }
} 