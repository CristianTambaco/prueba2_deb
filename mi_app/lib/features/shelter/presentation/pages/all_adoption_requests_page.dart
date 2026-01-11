// lib/features/shelter/presentation/pages/all_adoption_requests_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_pro/core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../adoption_request/domain/entities/adoption_request_entity.dart';
import '../../../adoption_request/domain/repositories/adoption_request_repository.dart';

class AllAdoptionRequestsPage extends StatefulWidget {
  const AllAdoptionRequestsPage({super.key});

  @override
  State<AllAdoptionRequestsPage> createState() => _AllAdoptionRequestsPageState();
}

class _AllAdoptionRequestsPageState extends State<AllAdoptionRequestsPage> {
  AdoptionStatus? _filterStatus;
  List<AdoptionRequestEntity> _allRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
    if (user == null) return;

    final result = await getIt<AdoptionRequestRepository>().getRequestsByShelter(user.id);
    setState(() {
      _allRequests = result.fold((l) => [], (r) => r);
    });
  }

  List<AdoptionRequestEntity> get _filteredRequests {
    if (_filterStatus == null) return _allRequests;
    return _allRequests.where((req) => req.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas las Solicitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Filtros como botones
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterButton('Todas', null),
                  _buildFilterButton('Pendientes', AdoptionStatus.pending),
                  _buildFilterButton('Aprobadas', AdoptionStatus.approved),
                  _buildFilterButton('Rechazadas', AdoptionStatus.rejected),
                ],
              ),

              const SizedBox(height: 16),

              // Lista de solicitudes
              Expanded(
                child: _filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == null
                                  ? 'No hay solicitudes aún'
                                  : 'No hay solicitudes ${_filterStatus!.name} en este momento',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final req = _filteredRequests[index];
                          return _buildRequestCard(
                            petName: req.petName,
                            requester: req.adopterName,
                            status: req.status,
                            onApprove: () async {
                              await getIt<AdoptionRequestRepository>()
                                  .updateStatus(req.id, AdoptionStatus.approved);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Solicitud aprobada')),
                                );
                                _loadRequests(); // Recargar la lista
                              }
                            },
                            onReject: () async {
                              await getIt<AdoptionRequestRepository>()
                                  .updateStatus(req.id, AdoptionStatus.rejected);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Solicitud rechazada')),
                                );
                                _loadRequests(); // Recargar la lista
                              }
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

  Widget _buildFilterButton(String label, AdoptionStatus? status) {
    final isSelected = _filterStatus == status;
    Color buttonColor = isSelected
        ? AppTheme.primaryColor.withOpacity(0.15)
        : Colors.white;
    Color textColor = isSelected
        ? AppTheme.primaryColor
        : Colors.black87;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filterStatus = isSelected ? null : status;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Icon(
              Icons.check_circle,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          const SizedBox(width: 4),
          Text(label),
        ],
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
    Color statusIconColor = Colors.grey[600]!;
    IconData statusIcon = Icons.hourglass_bottom_outlined;
    Color borderColor = Colors.grey[200]!;

    switch (status) {
      case AdoptionStatus.pending:
        cardColor = Colors.yellow[50]!;
        statusIconColor = Colors.orange[700]!;
        statusIcon = Icons.hourglass_bottom_outlined;
        borderColor = Colors.orange[200]!;
        break;
      case AdoptionStatus.approved:
        cardColor = Colors.green[50]!;
        statusIconColor = Colors.green[700]!;
        statusIcon = Icons.check_circle_outline;
        borderColor = Colors.green[200]!;
        break;
      case AdoptionStatus.rejected:
        cardColor = Colors.red[50]!;
        statusIconColor = Colors.red[700]!;
        statusIcon = Icons.cancel_outlined;
        borderColor = Colors.red[200]!;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Icon(
              Icons.pets,
              size: 24,
              color: Colors.grey[600],
            ),
          ),
        ),
        title: Text(
          'Solicitud para $petName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'De: $requester',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusIconColor),
                  const SizedBox(width: 4),
                  Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusIconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              backgroundColor: statusIconColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == AdoptionStatus.pending)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF007AFF)),
                onPressed: onApprove,
                tooltip: 'Aprobar',
              ),
            if (status == AdoptionStatus.pending)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
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