import 'package:equatable/equatable.dart';

class PetEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? age;
  final String type; // 'perro', 'gato'
  final String shelterId;
  final DateTime createdAt;

  const PetEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.age,
    required this.type,
    required this.shelterId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, imageUrl, age, type, shelterId, createdAt];
}