import 'package:equatable/equatable.dart';

enum AdoptionStatus { pending, approved, rejected }

class AdoptionRequestEntity extends Equatable {
  final String id;
  final String petId;
  final String petName;
  final String adopterId;
  final String adopterName;
  final String shelterId;
  final AdoptionStatus status;
  final DateTime createdAt;

  const AdoptionRequestEntity({
    required this.id,
    required this.petId,
    required this.petName,
    required this.adopterId,
    required this.adopterName,
    required this.shelterId,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        petId,
        petName,
        adopterId,
        adopterName,
        shelterId,
        status,
        createdAt,
      ];
}