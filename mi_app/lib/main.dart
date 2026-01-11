import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';

import 'injection_container.dart';
import 'features/auth/domain/entities/user_entity.dart'; 
import 'features/adopter/presentation/pages/adopter_home_page.dart'; 
import 'features/shelter/presentation/pages/shelter_home_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp(
        title: 'Login ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (state is AuthAuthenticated) {
              if (state.user.userType == UserType.refugio) {
                return const ShelterHomePage();
              } else {
                return const AdopterHomePage();
              }
            } else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}
