import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/adoption_request_entity.dart';
import '../../domain/repositories/adoption_request_repository.dart';

class AdoptionRequestRepositoryImpl implements AdoptionRequestRepository {
  final SupabaseClient supabase;

  AdoptionRequestRepositoryImpl(this.supabase);

  @override
  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByShelter(String shelterId) async {
    try {
      final response = await supabase
          .from('adoption_requests')
          .select()
          .eq('shelter_id', shelterId)
          .order('created_at', ascending: false);

      final requests = (response as List).map((e) => AdoptionRequestEntity(
            id: e['id'],
            petId: e['pet_id'],
            petName: e['pet_name'],
            adopterId: e['adopter_id'],
            adopterName: e['adopter_name'],
            shelterId: e['shelter_id'],
            status: _statusFromString(e['status']),
            createdAt: DateTime.parse(e['created_at']),
          )).toList();

      return Right(requests);
    } catch (e) {
      return Left(ServerFailure('Error al cargar solicitudes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByAdopter(String adopterId) async {
    try {
      final response = await supabase
          .from('adoption_requests')
          .select()
          .eq('adopter_id', adopterId)
          .order('created_at', ascending: false);

      final requests = (response as List).map((e) => AdoptionRequestEntity(
            id: e['id'],
            petId: e['pet_id'],
            petName: e['pet_name'],
            adopterId: e['adopter_id'],
            adopterName: e['adopter_name'],
            shelterId: e['shelter_id'],
            status: _statusFromString(e['status']),
            createdAt: DateTime.parse(e['created_at']),
          )).toList();

      return Right(requests);
    } catch (e) {
      return Left(ServerFailure('Error al cargar tus solicitudes: $e'));
    }
  }

  @override
  Future<Either<Failure, AdoptionRequestEntity>> createRequest({
    required String petId,
    required String petName,
    required String adopterId,
    required String adopterName,
    required String shelterId,
  }) async {
    try {
      final response = await supabase.from('adoption_requests').insert({
        'pet_id': petId,
        'pet_name': petName,
        'adopter_id': adopterId,
        'adopter_name': adopterName,
        'shelter_id': shelterId,
        'status': 'pending',
      }).select().single();

      return Right(AdoptionRequestEntity(
        id: response['id'],
        petId: response['pet_id'],
        petName: response['pet_name'],
        adopterId: response['adopter_id'],
        adopterName: response['adopter_name'],
        shelterId: response['shelter_id'],
        status: AdoptionStatus.pending,
        createdAt: DateTime.parse(response['created_at']),
      ));
    } catch (e) {
      return Left(ServerFailure('Error al crear solicitud: $e'));
    }
  }

  @override
  Future<Either<Failure, AdoptionRequestEntity>> updateStatus(String requestId, AdoptionStatus status) async {
    try {
      final response = await supabase
          .from('adoption_requests')
          .update({'status': _statusToString(status)})
          .eq('id', requestId)
          .select()
          .single();

      return Right(AdoptionRequestEntity(
        id: response['id'],
        petId: response['pet_id'],
        petName: response['pet_name'],
        adopterId: response['adopter_id'],
        adopterName: response['adopter_name'],
        shelterId: response['shelter_id'],
        status: _statusFromString(response['status']),
        createdAt: DateTime.parse(response['created_at']),
      ));
    } catch (e) {
      return Left(ServerFailure('Error al actualizar estado: $e'));
    }
  }

  AdoptionStatus _statusFromString(String status) {
    switch (status) {
      case 'approved': return AdoptionStatus.approved;
      case 'rejected': return AdoptionStatus.rejected;
      default: return AdoptionStatus.pending;
    }
  }

  String _statusToString(AdoptionStatus status) {
    switch (status) {
      case AdoptionStatus.approved: return 'approved';
      case AdoptionStatus.rejected: return 'rejected';
      case AdoptionStatus.pending: return 'pending';
    }
  }
}