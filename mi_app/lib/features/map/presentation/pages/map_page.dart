import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _userLocation;
  bool _loading = true;
  List<Map<String, dynamic>> _shelters = []; // Datos desde Supabase

  @override
  void initState() {
    super.initState();
    _loadData();
  }



  void _showShelterDetails(Map<String, dynamic> shelter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  const Icon(Icons.home, color: Color(0xFF6C5CE7), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shelter['shelter_name'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1),

              // Dirección
              if (shelter['address'] != null)
                _buildDetailRow('📍 Dirección', shelter['address'] as String),

              // Ciudad y País
              _buildDetailRow('🌍 Ubicación', '${shelter['city']}, ${shelter['country']}'),

              // Teléfono
              if (shelter['phone'] != null)
                _buildDetailRow('📞 Teléfono', shelter['phone'] as String),

              // Sitio web
              if (shelter['website'] != null)
                _buildDetailRow('🌐 Sitio Web', shelter['website'] as String),

              
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF636E72)),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }






  Future<void> _loadData() async {
    await _determinePosition();
    await _loadSheltersFromSupabase();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Silenciosamente manejar error de ubicación
    }
  }

  Future<void> _loadSheltersFromSupabase() async {
    try {
      final response = await getIt<SupabaseClient>().from('shelters').select();
      setState(() {
        _shelters = response as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar refugios: $e')),
      );
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refugios Cercanos'),
        backgroundColor: const Color(0xFFFF8C42),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _userLocation ?? const LatLng(-0.1807, -78.4678),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.login_pro',
                ),
                // Marcador del usuario
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: _userLocation!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                          child: const Icon(Icons.my_location, size: 20, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                // Marcadores de refugios desde Supabase
                MarkerLayer(
                  markers: _shelters.map((shelter) {
                    return Marker(
                    width: 80,
                    height: 80,
                    point: LatLng(
                      (shelter['latitude'] as num).toDouble(),
                      (shelter['longitude'] as num).toDouble(),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _showShelterDetails(shelter);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: const Icon(Icons.home, color: Color(0xFF6C5CE7), size: 36),
                      ),
                    ),
                  );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}