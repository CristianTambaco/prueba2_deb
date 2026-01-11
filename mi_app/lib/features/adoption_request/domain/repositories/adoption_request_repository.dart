import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/adoption_request_entity.dart';

abstract class AdoptionRequestRepository {
  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByShelter(String shelterId);
  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByAdopter(String adopterId);
  Future<Either<Failure, AdoptionRequestEntity>> createRequest({
    required String petId,
    required String petName,
    required String adopterId,
    required String adopterName,
    required String shelterId,
  });
  Future<Either<Failure, AdoptionRequestEntity>> updateStatus(String requestId, AdoptionStatus status);
}