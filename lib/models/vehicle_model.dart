class VehicleModel {
  final String id;
  final String driverId;
  final String brand;
  final String model;
  final String color;
  final String licensePlate;
  final String year;
  final int seats;

  VehicleModel({
    required this.id,
    required this.driverId,
    required this.brand,
    required this.model,
    required this.color,
    required this.licensePlate,
    required this.year,
    required this.seats,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'brand': brand,
      'model': model,
      'color': color,
      'licensePlate': licensePlate,
      'year': year,
      'seats': seats,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      color: map['color'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      year: map['year']?.toString() ?? '',
      seats: map['seats'] ?? 0,
    );
  }
} 