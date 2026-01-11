// lib/features/adopter/presentation/pages/adopter_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_pro/features/auth/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../pet/domain/entities/pet_entity.dart';
import '../../../pet/domain/repositories/pet_repository.dart';
import '../../../adoption_request/domain/repositories/adoption_request_repository.dart';
import '../../../gemini_chat/presentation/screens/chat_screen.dart';
import '../../../gemini_chat/cubits/chat_cubit.dart';
import '../../../gemini_chat/services/gemini_service.dart';
import '../pages/my_adoption_requests_page.dart'; // 

class AdopterHomePage extends StatefulWidget {
  const AdopterHomePage({super.key});

  @override
  State<AdopterHomePage> createState() => _AdopterHomePageState();
}

class _AdopterHomePageState extends State<AdopterHomePage> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    // 
    if (index == 1 || index == 4) {
      return; 
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      // Chat IA
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => ChatCubit(getIt<GeminiService>()),
            child: const ChatScreen(),
          ),
        ),
      );
    } else if (index == 3) {
      // Mis Solicitudes
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyAdoptionRequestsPage()),
      );
    } else if (index == 4) {
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Adoptante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const SignOutRequested());
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<PetEntity>>(
          future: getIt<PetRepository>()
              .getAllPets()
              .then((r) => r.fold((l) => [], (r) => r)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final pets = snapshot.data ?? [];
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hola, ${user?.displayName ?? user?.email.split('@').first}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Text('👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Encuentra tu mascota',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search, color: Color(0xFF636E72)),
                              hintText: 'Buscar mascota...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildFilterButton('Todos', true),
                            const SizedBox(width: 8),
                            _buildFilterButton('Perros', false),
                            const SizedBox(width: 8),
                            _buildFilterButton('Gatos', false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildPetCard(pet: pets[index], context: context);
                      },
                      childCount: pets.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF8C42),
        unselectedItemColor: const Color(0xFF636E72),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat IA'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Solicitudes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        onTap: _navigateTo,
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFFF8C42) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF2D3436),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Text(text),
    );
  }

  Widget _buildPetCard({required PetEntity pet, required BuildContext context}) {
    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state is AuthAuthenticated ? (authBloc.state as AuthAuthenticated).user : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: pet.imageUrl != null
                  ? DecorationImage(image: NetworkImage(pet.imageUrl!), fit: BoxFit.cover)
                  : null,
              color: pet.imageUrl == null ? Colors.grey[200] : null,
            ),
            child: pet.imageUrl == null
                ? const Icon(Icons.pets, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${pet.type} • ${pet.age} años',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: user != null
                      ? () async {
                          final result = await getIt<AdoptionRequestRepository>().createRequest(
                            petId: pet.id,
                            petName: pet.name,
                            adopterId: user.id,
                            adopterName: user.displayName ?? user.email.split('@').first,
                            shelterId: pet.shelterId,
                          );
                          if (result.isRight()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Solicitud enviada con éxito')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${result.fold((l) => l.message, (_) => '')}')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.pets, size: 16),
                  label: const Text('Solicitar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}