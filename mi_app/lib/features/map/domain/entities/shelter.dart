import 'package:equatable/equatable.dart';

class Shelter extends Equatable {
  final String id;
  final String shelterName;
  final String? address;
  final String city;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;

  const Shelter({
    required this.id,
    required this.shelterName,
    this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
  });

  @override
  List<Object?> get props => [id, shelterName, address, city, latitude, longitude];
}