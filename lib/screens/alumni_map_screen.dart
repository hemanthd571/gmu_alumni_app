import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AlumniMapScreen extends StatefulWidget {
  const AlumniMapScreen({super.key});

  @override
  State<AlumniMapScreen> createState() => _AlumniMapScreenState();
}

class _AlumniMapScreenState extends State<AlumniMapScreen> {
  MapController? _mapController;
  List<Marker> _markers = [];
  bool _isLoading = true;
  LatLng _initialPosition = LatLng(12.9716, 77.5946); // Bangalore default

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadAlumniLocations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(position.latitude, position.longitude);
        });
      }

      // Update user location in database
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      try {
        await ApiService.post('/location/update.php', data: {
          'user_id': int.parse(userId),
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        print('✅ Location updated: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('❌ Failed to update location: $e');
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadAlumniLocations() async {
    try {
      final response = await ApiService.get('/location/alumni_map.php');
      final data = response.data;

      if (data['success']) {
        final alumni = data['data'] as List;
        final markers = <Marker>[];

        for (var alumnus in alumni) {
          markers.add(
            Marker(
              point: LatLng(alumnus['latitude'], alumnus['longitude']),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(alumnus['name']),
                      content: Text(
                        'USN: ${alumnus['usn']}\n'
                        'Batch: ${alumnus['batch'] ?? "N/A"}\n'
                        'Department: ${alumnus['department'] ?? "N/A"}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: alumnus['profilePicture'] != null && alumnus['profilePicture'].toString().isNotEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppConfig.primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(AppConfig.getProfileImageUrl(alumnus['profilePicture'])),
                          backgroundColor: Colors.white,
                          child: alumnus['profilePicture'] == null 
                            ? Text(
                                alumnus['name'].substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.primaryColor),
                              )
                            : null,
                        ),
                      )
                    : const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
              ),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _markers = markers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alumni locations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Map'),
        backgroundColor: AppConfig.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAlumniLocations();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _initialPosition,
                zoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gmu.alumni',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
