import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Importa geolocator

// Modelo simple de refugio
class Shelter {
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  const Shelter({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _userLocation;
  bool _loading = true;
  final List<Shelter> _shelters = [
    Shelter(
      name: 'Refugio Patitas Felices',
      latitude: -0.1807,
      longitude: -78.4678,
      address: 'Av. 6 de Diciembre N34-123, Quito',
    ),
    Shelter(
      name: 'Hogar Canino Esperanza',
      latitude: -0.2000,
      longitude: -78.5000,
      address: 'Calle Olmedo Oe1-45, Quito',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor activa los servicios de ubicación')),
      );
      _loading = false;
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
    permission == LocationPermission.denied) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado')),
      );
      _loading = false;
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      _loading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refugios Cercanos'),
        backgroundColor: const Color(0xFF6C5CE7),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // ✅ Elimina espacios extra
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
                // Marcadores de refugios
                MarkerLayer(
                  markers: _shelters.map((shelter) {
                    return Marker(
                      width: 80,
                      height: 80,
                      point: LatLng(shelter.latitude, shelter.longitude),
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(shelter.name)),
                          );
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