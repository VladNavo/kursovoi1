import 'package:equatable/equatable.dart';
import 'package:kursovoi1/models/ride_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, cancelled, noShow }

class BookingModel extends Equatable {
  final String id;
  final String routeId;
  final String userId;
  final String driverId;
  final int seats;
  final double totalPrice;
  final BookingStatus status;
  final String paymentMethod;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.routeId,
    required this.userId,
    required this.driverId,
    required this.seats,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      routeId: map['routeId'] as String,
      userId: map['userId'] as String,
      driverId: map['driverId'] as String,
      seats: map['seats'] as int,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'userId': userId,
      'driverId': driverId,
      'seats': seats,
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BookingModel copyWith({
    String? id,
    String? routeId,
    String? userId,
    String? driverId,
    int? seats,
    double? totalPrice,
    BookingStatus? status,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeId,
        userId,
        driverId,
        seats,
        totalPrice,
        status,
        paymentMethod,
        createdAt,
      ];
} 