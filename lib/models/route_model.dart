import 'package:equatable/equatable.dart';

class RouteModel extends Equatable {
  final String id;
  final String startPoint;
  final String endPoint;
  final DateTime departureTime;
  final int availableSeats;
  final String driverId;
  final List<String> passengerIds;
  final double price;
  final String status;

  const RouteModel({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    required this.departureTime,
    required this.availableSeats,
    required this.driverId,
    this.passengerIds = const [],
    required this.price,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'departureTime': departureTime.toIso8601String(),
      'availableSeats': availableSeats,
      'driverId': driverId,
      'passengerIds': passengerIds,
      'price': price,
      'status': status,
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      startPoint: json['startPoint'] as String,
      endPoint: json['endPoint'] as String,
      departureTime: DateTime.parse(json['departureTime'] as String),
      availableSeats: json['availableSeats'] as int,
      driverId: json['driverId'] as String,
      passengerIds: List<String>.from(json['passengerIds'] ?? []),
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String? ?? 'active',
    );
  }

  @override
  List<Object?> get props => [
        id,
        startPoint,
        endPoint,
        departureTime,
        availableSeats,
        driverId,
        passengerIds,
        price,
        status,
      ];
} 