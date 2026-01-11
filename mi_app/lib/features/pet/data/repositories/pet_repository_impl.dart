import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/repositories/pet_repository.dart';

class PetRepositoryImpl implements PetRepository {
  final SupabaseClient supabase;

  PetRepositoryImpl(this.supabase);

  @override
  Future<Either<Failure, List<PetEntity>>> getAllPets() async {
    try {
      final response = await supabase.from('pets').select().order('created_at', ascending: false);
      final pets = (response as List)
          .map((e) => PetEntity(
                id: e['id'],
                name: e['name'],
                description: e['description'],
                imageUrl: e['image_url'],
                age: e['age'],
                type: e['type'],
                shelterId: e['shelter_id'],
                createdAt: DateTime.parse(e['created_at']),
              ))
          .toList();
      return Right(pets);
    } catch (e) {
      return Left(ServerFailure('Error al cargar mascotas: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PetEntity>>> getPetsByShelter(String shelterId) async {
    try {
      final response = await supabase
          .from('pets')
          .select()
          .eq('shelter_id', shelterId)
          .order('created_at', ascending: false);
      final pets = (response as List)
          .map((e) => PetEntity(
                id: e['id'],
                name: e['name'],
                description: e['description'],
                imageUrl: e['image_url'],
                age: e['age'],
                type: e['type'],
                shelterId: e['shelter_id'],
                createdAt: DateTime.parse(e['created_at']),
              ))
          .toList();
      return Right(pets);
    } catch (e) {
      return Left(ServerFailure('Error al cargar tus mascotas: $e'));
    }
  }

  @override
  Future<Either<Failure, PetEntity>> createPet(PetEntity pet, String? imagePath) async {
    try {
      String? imageUrl;
      if (imagePath != null) {
        final file = File(imagePath);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        await supabase.storage.from('pet-images').upload(fileName, file);
        final url = supabase.storage.from('pet-images').getPublicUrl(fileName);
        imageUrl = url;
      }

      final response = await supabase.from('pets').insert({
        'name': pet.name,
        'description': pet.description,
        'image_url': imageUrl,
        'age': pet.age,
        'type': pet.type,
        'shelter_id': pet.shelterId,
      }).select().single();

      return Right(PetEntity(
        id: response['id'],
        name: response['name'],
        description: response['description'],
        imageUrl: response['image_url'],
        age: response['age'],
        type: response['type'],
        shelterId: response['shelter_id'],
        createdAt: DateTime.parse(response['created_at']),
      ));
    } catch (e) {
      return Left(ServerFailure('Error al crear mascota: $e'));
    }
  }

  @override
  Future<Either<Failure, PetEntity>> updatePet(PetEntity pet, String? imagePath) async {
    try {
      String? imageUrl = pet.imageUrl;
      if (imagePath != null) {
        // Opcional: eliminar imagen anterior
        final fileName = pet.imageUrl?.split('/').last.split('?')[0];
        if (fileName != null) {
          try {
            await supabase.storage.from('pet-images').remove([fileName]);
          } catch (_) {}
        }

        final file = File(imagePath);
        final newFileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        await supabase.storage.from('pet-images').upload(newFileName, file);
        imageUrl = supabase.storage.from('pet-images').getPublicUrl(newFileName);
      }

      final response = await supabase
          .from('pets')
          .update({
            'name': pet.name,
            'description': pet.description,
            'image_url': imageUrl,
            'age': pet.age,
            'type': pet.type,
          })
          .eq('id', pet.id)
          .select()
          .single();

      return Right(PetEntity(
        id: response['id'],
        name: response['name'],
        description: response['description'],
        imageUrl: response['image_url'],
        age: response['age'],
        type: response['type'],
        shelterId: response['shelter_id'],
        createdAt: DateTime.parse(response['created_at']),
      ));
    } catch (e) {
      return Left(ServerFailure('Error al actualizar mascota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePet(String petId) async {
    try {
      await supabase.from('pets').delete().eq('id', petId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar mascota: $e'));
    }
  }
}