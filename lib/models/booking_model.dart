import 'package:equatable/equatable.dart';
import 'package:kursovoi1/models/ride_model.dart';

enum BookingStatus {
  pending,    // Ожидает подтверждения
  confirmed,  // Подтверждено
  completed,  // Завершено
  cancelled,  // Отменено
}

class BookingModel extends Equatable {
  final String id;
  final String userId;
  final RideModel ride;
  final DateTime bookingDate;
  final BookingStatus status;
  final int seats;
  final int totalPrice;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.ride,
    required this.bookingDate,
    required this.status,
    required this.seats,
    required this.totalPrice,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      ride: RideModel.fromJson(json['ride'] as Map<String, dynamic>),
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      status: BookingStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      seats: json['seats'] as int,
      totalPrice: json['totalPrice'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ride': ride.toJson(),
      'bookingDate': bookingDate.toIso8601String(),
      'status': status.toString(),
      'seats': seats,
      'totalPrice': totalPrice,
    };
  }

  @override
  List<Object?> get props => [id, userId, ride, bookingDate, status, seats, totalPrice];
} 