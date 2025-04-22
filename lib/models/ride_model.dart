import 'package:equatable/equatable.dart';

class RideModel extends Equatable {
  final String id;
  final String from;
  final String to;
  final DateTime departureTime;
  final int price;
  final int totalSeats;
  final int availableSeats;
  final String driverId;
  final String carModel;
  final String carNumber;
  final List<String> amenities;
  final bool cashOnly;
  final List<String> bookedPassengers;

  const RideModel({
    required this.id,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.driverId,
    required this.carModel,
    required this.carNumber,
    this.amenities = const [],
    this.cashOnly = false,
    this.bookedPassengers = const [],
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      departureTime: DateTime.parse(json['departureTime'] as String),
      price: json['price'] as int,
      totalSeats: json['totalSeats'] as int,
      availableSeats: json['availableSeats'] as int,
      driverId: json['driverId'] as String,
      carModel: json['carModel'] as String,
      carNumber: json['carNumber'] as String,
      amenities: List<String>.from(json['amenities'] ?? []),
      cashOnly: json['cashOnly'] as bool? ?? false,
      bookedPassengers: List<String>.from(json['bookedPassengers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'departureTime': departureTime.toIso8601String(),
      'price': price,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'driverId': driverId,
      'carModel': carModel,
      'carNumber': carNumber,
      'amenities': amenities,
      'cashOnly': cashOnly,
      'bookedPassengers': bookedPassengers,
    };
  }

  RideModel copyWith({
    String? id,
    String? from,
    String? to,
    DateTime? departureTime,
    int? price,
    int? totalSeats,
    int? availableSeats,
    String? driverId,
    String? carModel,
    String? carNumber,
    List<String>? amenities,
    bool? cashOnly,
    List<String>? bookedPassengers,
  }) {
    return RideModel(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      driverId: driverId ?? this.driverId,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      amenities: amenities ?? this.amenities,
      cashOnly: cashOnly ?? this.cashOnly,
      bookedPassengers: bookedPassengers ?? this.bookedPassengers,
    );
  }

  @override
  List<Object?> get props => [
        id,
        from,
        to,
        departureTime,
        price,
        totalSeats,
        availableSeats,
        driverId,
        carModel,
        carNumber,
        amenities,
        cashOnly,
        bookedPassengers,
      ];
} 