import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_pro/features/auth/presentation/pages/profile_page.dart';

import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../adoption_request/domain/entities/adoption_request_entity.dart';
import '../../../adoption_request/domain/repositories/adoption_request_repository.dart';
import '../pages/shelter_pets_page.dart';
import '../pages/all_adoption_requests_page.dart';

class ShelterHomePage extends StatelessWidget {
  const ShelterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C897),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Refugio Patitas Felices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Panel de administración',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const SignOutRequested());
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // ✅ BODY SIN OVERFLOW
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomScrollView(
            slivers: [
              /// ---------- HEADER + STATS ----------
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saludo
                    Row(
                      children: [
                        Text(
                          'Bienvenido, ${user?.displayName ?? user?.email.split('@').first}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('👋', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Estadísticas
                    FutureBuilder<List<AdoptionRequestEntity>>(
                      future: getIt<AdoptionRequestRepository>()
                          .getRequestsByShelter(user?.id ?? '')
                          .then((r) => r.fold((l) => [], (r) => r)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final requests = snapshot.data ?? [];
                        final pending = requests
                            .where((r) => r.status == AdoptionStatus.pending)
                            .length;
                        final approved = requests
                            .where((r) => r.status == AdoptionStatus.approved)
                            .length;

                        return Row(
                          children: [
                            _buildStatCard(
                              count: '$pending',
                              label: 'Pendientes',
                              color: const Color(0xFFFF9F40),
                              iconColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              count: '$approved',
                              label: 'Adoptadas',
                              color: const Color(0xFF00D2A1),
                              iconColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              count: '${requests.length}',
                              label: 'Solicitudes',
                              color: const Color(0xFF6C5CE7),
                              iconColor: Colors.white,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Header solicitudes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Solicitudes Recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllAdoptionRequestsPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Ver todas',
                            style: TextStyle(color: Color(0xFFFF6B6B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              /// ---------- LISTA SCROLLABLE ----------
              SliverFillRemaining(
                child: FutureBuilder<List<AdoptionRequestEntity>>(
                  future: getIt<AdoptionRequestRepository>()
                      .getRequestsByShelter(user?.id ?? '')
                      .then((r) => r.fold((l) => [], (r) => r)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data ?? [];

                    if (requests.isEmpty) {
                      return const Center(
                        child: Text('No hay solicitudes aún'),
                      );
                    }

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return _buildRequestCard(
                          petName: req.petName,
                          requester: req.adopterName,
                          status: req.status,
                          onApprove: () async {
                            await getIt<AdoptionRequestRepository>()
                                .updateStatus(req.id, AdoptionStatus.approved);
                          },
                          onReject: () async {
                            await getIt<AdoptionRequestRepository>()
                                .updateStatus(req.id, AdoptionStatus.rejected);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: const Color(0xFF636E72),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            label: 'Mascotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          if (index == 1) { // Navegar a la página de mascotas
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShelterPetsPage()),
            );
          } else if (index == 2) { // Navegar a la página de solicitudes
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllAdoptionRequestsPage()),
            );
          } else if (index == 3) { 
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard({
    required String petName,
    required String requester,
    required AdoptionStatus status,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    Color cardColor = Colors.white;
    Color statusIconColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_bottom_outlined;

    switch (status) {
      case AdoptionStatus.pending:
        cardColor = const Color(0xFFFFF5E6); // Fondo amarillo claro
        statusIconColor = const Color(0xFFFF9F40); // Naranja
        statusIcon = Icons.hourglass_bottom_outlined;
        break;
      case AdoptionStatus.approved:
        cardColor = const Color(0xFFF0FBE8); // Fondo verde claro
        statusIconColor = const Color(0xFF00D2A1); // Verde
        statusIcon = Icons.check_circle_outline;
        break;
      case AdoptionStatus.rejected:
        cardColor = const Color(0xFFFFF0F0); // Fondo rojo claro
        statusIconColor = const Color(0xFFFF6B6B); // Rojo
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Icons.pets, size: 20, color: Colors.grey[600]),
          ),
        ),
        title: Text(
          'Solicitud para $petName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: $requester'),
            const SizedBox(height: 4),
            Chip(
              side: BorderSide.none,
              label: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusIconColor),
                  const SizedBox(width: 4),
                  Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusIconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: statusIconColor.withOpacity(0.1),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == AdoptionStatus.pending)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00D2A1)),
                onPressed: onApprove,
                tooltip: 'Aprobar',
              ),
            if (status == AdoptionStatus.pending)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Color(0xFFFF6B6B)),
                onPressed: onReject,
                tooltip: 'Rechazar',
              ),
            if (status != AdoptionStatus.pending)
              Icon(
                status == AdoptionStatus.approved
                    ? Icons.check_circle
                    : Icons.cancel,
                color: statusIconColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}