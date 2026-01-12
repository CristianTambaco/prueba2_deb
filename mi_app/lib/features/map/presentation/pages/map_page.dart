import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:login_pro/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<dynamic>> _sheltersFuture;

  @override
  void initState() {
    super.initState();
    _sheltersFuture = _loadShelters();
  }

  Future<List<dynamic>> _loadShelters() async {
    final response = await getIt<SupabaseClient>().from('shelters').select();
    return response as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refugios cercanos'),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _sheltersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar refugios'));
          }

          final shelters = snapshot.data!;
          final markers = shelters.map((shelter) {
            return Marker(
  width: 80.0,
  height: 80.0,
  point: LatLng(
    (shelter['latitude'] as num).toDouble(),
    (shelter['longitude'] as num).toDouble(),
  ),
  child: GestureDetector(
    onTap: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shelter['shelter_name'])),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 2)
        ],
      ),
      child: const Icon(Icons.home, color: Color(0xFF6C5CE7), size: 36),
    ),
  ),
);
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(-0.1807, -78.4678), // Quito
              initialZoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.login_pro',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}