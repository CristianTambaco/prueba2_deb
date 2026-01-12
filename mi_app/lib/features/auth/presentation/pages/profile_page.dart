

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/user_entity.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color.fromARGB(255, 190, 106, 9),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
  child: BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state is AuthAuthenticated) {
        final user = state.user;
        final isShelter = user.userType == UserType.refugio;
        final roleName = isShelter ? 'Refugio' : 'Adoptante';
        final roleColor = isShelter ? Colors.orange : Colors.blue;

        return SingleChildScrollView(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: roleColor.withOpacity(0.1),
          child: Icon(
            isShelter ? Icons.home_work : Icons.person,
            size: 60,
            color: roleColor,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          user.displayName ?? user.email.split('@').first,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleColor.withOpacity(0.4)),
          ),
          child: Text(
            roleName,
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (user.email != null)
          Text(
            user.email!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    ),
  ),
);

      } else {
        return const Center(
          child: Text(
            'No estás autenticado',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
    },
  ),
),

    );
  }
}