import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'injection_container.config.dart';

import 'package:supabase/supabase.dart';

// Importa los nuevos repositorios
import 'features/pet/domain/repositories/pet_repository.dart';
import 'features/pet/data/repositories/pet_repository_impl.dart';
import 'features/adoption_request/domain/repositories/adoption_request_repository.dart'; // ✅
import 'features/adoption_request/data/repositories/adoption_request_repository_impl.dart'; // ✅


import 'features/gemini_chat/services/gemini_service.dart';
import 'features/gemini_chat/services/tts_service.dart';


final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Pet Repository
  getIt.registerLazySingleton<PetRepository>(
    () => PetRepositoryImpl(getIt<SupabaseClient>()),
  );

  // Adoption Request Repository ✅
  getIt.registerLazySingleton<AdoptionRequestRepository>(
    () => AdoptionRequestRepositoryImpl(getIt<SupabaseClient>()),
  );


  getIt.registerLazySingleton<GeminiService>(() => GeminiService());
  getIt.registerLazySingleton<TtsService>(() => TtsService());


  // Initialize injectable
  getIt.init();
}