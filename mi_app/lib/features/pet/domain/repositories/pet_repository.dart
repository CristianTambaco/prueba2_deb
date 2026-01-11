import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pet_entity.dart';

abstract class PetRepository {
  Future<Either<Failure, List<PetEntity>>> getAllPets();
  Future<Either<Failure, List<PetEntity>>> getPetsByShelter(String shelterId);
  Future<Either<Failure, PetEntity>> createPet(PetEntity pet, String? imagePath);
  Future<Either<Failure, PetEntity>> updatePet(PetEntity pet, String? imagePath);
  Future<Either<Failure, void>> deletePet(String petId);
}