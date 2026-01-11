// lib/features/adopter/presentation/pages/my_adoption_requests_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../adoption_request/domain/entities/adoption_request_entity.dart';
import '../../../adoption_request/domain/repositories/adoption_request_repository.dart';

class MyAdoptionRequestsPage extends StatefulWidget {
  const MyAdoptionRequestsPage({super.key});

  @override
  State<MyAdoptionRequestsPage> createState() => _MyAdoptionRequestsPageState();
}

class _MyAdoptionRequestsPageState extends State<MyAdoptionRequestsPage> {
  late Future<List<AdoptionRequestEntity>> _requestsFuture;
  AdoptionStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
    if (user != null) {
      setState(() {
        _requestsFuture = getIt<AdoptionRequestRepository>()
            .getRequestsByAdopter(user.id)
            .then((r) => r.fold((l) => [], (r) => r));
      });
    }
  }

  // List<AdoptionRequestEntity> get _filteredRequests {
  //   if (_filterStatus == null) return [];
  //   return (_requestsFuture.snapshot.data ?? []).where((req) => req.status == _filterStatus).toList();
  // }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        backgroundColor: const Color(0xFFFF8C42), // Naranja PetAdopt
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filtros
              Row(
                children: [
                  _buildFilterChip('Todas', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendientes', AdoptionStatus.pending),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aprobadas', AdoptionStatus.approved),
                ],
              ),
              const SizedBox(height: 16),
              // Lista
              Expanded(
                child: FutureBuilder<List<AdoptionRequestEntity>>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final requests = snapshot.data ?? [];
                    final filtered = _filterStatus == null
                        ? requests
                        : requests.where((req) => req.status == _filterStatus).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No tienes solicitudes en este estado.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final req = filtered[index];
                        return _buildRequestCard(req);
                      },
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

  Widget _buildFilterChip(String label, AdoptionStatus? status) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
      selectedColor: const Color(0xFFFF8C42), // Naranja seleccionado
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: _filterStatus == status ? Colors.white : Colors.black),
    );
  }

  Widget _buildRequestCard(AdoptionRequestEntity req) {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    switch (req.status) {
      case AdoptionStatus.pending:
        statusText = 'Pendiente';
        statusColor = const Color(0xFFFF9F40); // Naranja claro
        statusIcon = Icons.hourglass_bottom_outlined;
        break;
      case AdoptionStatus.approved:
        statusText = 'Aprobada';
        statusColor = const Color(0xFF00D2A1); // Verde
        statusIcon = Icons.check_circle_outline;
        break;
      case AdoptionStatus.rejected:
        statusText = 'Rechazada';
        statusColor = const Color(0xFFFF6B6B); // Rojo
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de mascota (puedes reemplazarlo por una imagen si lo deseas)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, size: 24, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.petName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Refugio: ${req.shelterId}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF636E72)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solicitado: ${req.createdAt.toLocal().day} ${_getMonthShort(req.createdAt.toLocal().month)} ${req.createdAt.toLocal().year}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
                  ),
                ],
              ),
            ),
            Chip(
              label: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusText, style: TextStyle(color: statusColor)),
                ],
              ),
              backgroundColor: statusColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthShort(int month) {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[month];
  }

  Future<void> _cancelRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar solicitud?'),
        content: const Text('¿Estás seguro de que deseas cancelar esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await getIt<AdoptionRequestRepository>()
          .updateStatus(requestId, AdoptionStatus.rejected);
      if (result.isRight()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud cancelada')));
        _loadRequests(); // Recargar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.fold((l) => l.message, (_) => "")}')),
        );
      }
    }
  }
}