import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RouteStatus {
  active,
  completed,
  cancelled
}

class RouteModel extends Equatable {
  final String id;
  final String startPoint;
  final String endPoint;
  final DateTime departureTime;
  final int availableSeats;
  final double price;
  final String driverId;
  final List<String> passengerIds;
  final RouteStatus status;
  final Duration? timeUntilDeparture;

  const RouteModel({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    required this.departureTime,
    required this.availableSeats,
    required this.price,
    required this.driverId,
    this.passengerIds = const [],
    this.status = RouteStatus.active,
    this.timeUntilDeparture,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDepartureTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      } else {
        throw FormatException('Неподдерживаемый формат даты: $value');
      }
    }

    return RouteModel(
      id: map['id'] as String,
      startPoint: map['startPoint'] as String,
      endPoint: map['endPoint'] as String,
      departureTime: parseDepartureTime(map['departureTime']),
      availableSeats: map['availableSeats'] as int,
      price: (map['price'] as num).toDouble(),
      driverId: map['driverId'] as String,
      passengerIds: (map['passengerIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      status: RouteStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'active'),
        orElse: () => RouteStatus.active,
      ),
      timeUntilDeparture: map['timeUntilDeparture'] != null 
          ? Duration(milliseconds: map['timeUntilDeparture'].inMilliseconds)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'departureTime': Timestamp.fromDate(departureTime),
      'availableSeats': availableSeats,
      'price': price,
      'driverId': driverId,
      'passengerIds': passengerIds,
      'status': status.toString().split('.').last,
    };
  }

  RouteModel copyWith({
    String? id,
    String? startPoint,
    String? endPoint,
    DateTime? departureTime,
    int? availableSeats,
    double? price,
    String? driverId,
    List<String>? passengerIds,
    RouteStatus? status,
    Duration? timeUntilDeparture,
  }) {
    return RouteModel(
      id: id ?? this.id,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      price: price ?? this.price,
      driverId: driverId ?? this.driverId,
      passengerIds: passengerIds ?? this.passengerIds,
      status: status ?? this.status,
      timeUntilDeparture: timeUntilDeparture ?? this.timeUntilDeparture,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startPoint,
        endPoint,
        departureTime,
        availableSeats,
        price,
        driverId,
        passengerIds,
        status,
        timeUntilDeparture,
      ];
} 