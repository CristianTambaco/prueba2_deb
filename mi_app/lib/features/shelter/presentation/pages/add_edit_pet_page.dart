import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../pet/domain/entities/pet_entity.dart';
import '../../../pet/domain/repositories/pet_repository.dart';

class AddEditPetPage extends StatefulWidget {
  final String shelterId;
  final PetEntity? pet; // Si es null → crear nueva mascota

  const AddEditPetPage({
    super.key,
    required this.shelterId,
    this.pet,
  });

  @override
  State<AddEditPetPage> createState() => _AddEditPetPageState();
}

class _AddEditPetPageState extends State<AddEditPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  String? _type;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _descriptionController.text = widget.pet!.description ?? '';
      _ageController.text = widget.pet!.age?.toString() ?? '';
      _type = widget.pet!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() == true) {
      final pet = PetEntity(
        id: widget.pet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: null, // Se actualizará en el repositorio si hay imagen
        age: int.tryParse(_ageController.text) ?? 0,
        type: _type ?? 'perro',
        shelterId: widget.shelterId,
        createdAt: DateTime.now(),
      );

      try {
        final repository = getIt<PetRepository>();
        final result = await (widget.pet == null
            ? repository.createPet(pet, _imageFile?.path)
            : repository.updatePet(pet, _imageFile?.path));

        if (result.isRight()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.pet == null ? 'Mascota agregada' : 'Mascota actualizada'),
            ),
          );
          Navigator.pop(context); // Volver a la lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.fold((l) => l.message, (r) => '')}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Agregar Mascota' : 'Editar Mascota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Imagen
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 48, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Selecciona una imagen',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Edad
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad (en años)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la edad';
                    }
                    if (int.tryParse(value) == null) {
                      return 'La edad debe ser un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipo
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _type = 'perro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _type == 'perro' ? Colors.blue : Colors.grey[300],
                          foregroundColor: _type == 'perro' ? Colors.white : Colors.black,
                        ),
                        child: const Text('Perro'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _type = 'gato'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _type == 'gato' ? Colors.blue : Colors.grey[300],
                          foregroundColor: _type == 'gato' ? Colors.white : Colors.black,
                        ),
                        child: const Text('Gato'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botón Enviar
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(widget.pet == null ? 'Agregar Mascota' : 'Actualizar Mascota'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}