import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../pet/domain/entities/pet_entity.dart';
import '../../../pet/domain/repositories/pet_repository.dart';
import '../pages/add_edit_pet_page.dart';

// Colores definidos localmente (puedes moverlos a tu AppColors si deseas)
const Color _primaryColor = Color(0xFFFF6B35); // Naranja cálido
const Color _secondaryColor = Color(0xFF4CAF50); // Verde suave
const Color _textDark = Color(0xFF2D2D2D);
const Color _textMedium = Color(0xFF757575);
const Color _deleteColor = Color(0xFFF44336);
const Color _editColor = Color(0xFF2196F3);

class ShelterPetsPage extends StatefulWidget {
  const ShelterPetsPage({super.key});

  @override
  State<ShelterPetsPage> createState() => _ShelterPetsPageState();
}

class _ShelterPetsPageState extends State<ShelterPetsPage> {
  List<PetEntity> _pets = [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    if (user == null) return;

    final result = await getIt<PetRepository>().getPetsByShelter(user.id);
    setState(() {
      _pets = result.fold((l) => [], (r) => r);
    });
  }

  Future<void> _deletePet(String petId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar mascota?'),
        content: const Text('¿Estás seguro de eliminar esta mascota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: _deleteColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await getIt<PetRepository>().deletePet(petId);
      if (result.isRight()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mascota eliminada')),
        );
        _loadPets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.fold((l) => l.message, (_) => '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    if (user == null) return const Center(child: Text('Error: No autenticado'));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Mascotas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00C897),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditPetPage(shelterId: user.id),
                ),
              ).then((_) => _loadPets());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lista de mascotas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(
                                  pet.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                                ),
                              )
                            : _buildFallbackAvatar(),
                        title: Text(
                          pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _textDark,
                          ),
                        ),
                        subtitle: Text(
                          '${pet.type} • ${pet.age} años',
                          style: TextStyle(
                            fontSize: 14,
                            color: _textMedium,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Editar',
                              child: IconButton(
                                icon: Icon(Icons.edit, color: _editColor),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditPetPage(
                                        shelterId: user.id,
                                        pet: pet,
                                      ),
                                    ),
                                  ).then((_) => _loadPets());
                                },
                              ),
                            ),
                            Tooltip(
                              message: 'Eliminar',
                              child: IconButton(
                                icon: Icon(Icons.delete_outline, color: _deleteColor),
                                onPressed: () => _deletePet(pet.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pets,
        color: _primaryColor,
        size: 24,
      ),
    );
  }
}