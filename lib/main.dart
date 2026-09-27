import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const VehicleTrackingApp());
}

class VehicleTrackingApp extends StatelessWidget {
  const VehicleTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vehicle Tracking System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              token: data['access_token'],
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? 'Login failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Tracking System'),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String token;

  const DashboardPage({
    super.key,
    required this.token,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? route;
  Map<String, dynamic>? vehicle;
  Map<String, dynamic>? location;
  List<dynamic> history = [];

  bool loading = true;

  Timer? refreshTimer;

  Map<String, String> get headers => {
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    loadDashboard();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshLocation(),
    );
  }
  Future<void> loadDashboard() async {
    try {
      final routeResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/me/route'),
        headers: headers,
      );

      final vehicleResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/me/vehicle'),
        headers: headers,
      );

      final locationResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/me/vehicle/location'),
        headers: headers,
      );

      final historyResponse = await http.get(
      Uri.parse('http://127.0.0.1:8000/me/vehicle/history'),
      headers: headers,
      );
      
      if (routeResponse.statusCode == 200 &&
      vehicleResponse.statusCode == 200 &&
      locationResponse.statusCode == 200 &&
      historyResponse.statusCode == 200) {
        final locationData = jsonDecode(locationResponse.body);

        setState(() {
          route = jsonDecode(routeResponse.body);
          vehicle = jsonDecode(vehicleResponse.body);
          history = jsonDecode(historyResponse.body);

          if (locationData['location'] != null) {
            location = locationData['location'];
          } else if (locationData['latitude'] != null) {
            location = locationData;
          } else {
            location = null;
          }

          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
        ),
      );
    }
  }

  Future<void> refreshLocation() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/me/vehicle/location'),
        headers: headers,
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);

        setState(() {
          if (data['location'] != null) {
            location = data['location'];
          } else if (data['latitude'] != null) {
            location = data;
          }
        });
      }
    } catch (_) {}
  }
  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Widget buildMap() {
    if (location == null) {
      return const Card(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Text('No GPS location available'),
          ),
        ),
      );
    }

    final latitude = (location!['latitude'] as num).toDouble();
    final longitude = (location!['longitude'] as num).toDouble();

    final vehiclePosition = LatLng(latitude, longitude);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 350,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: vehiclePosition,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: vehiclePosition,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.directions_bus,
                    size: 45,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehicle Tracking',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: const Text('Assigned Route'),
                      subtitle: Text(
                        route?['name'] ?? 'Unknown',
                      ),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: const Text('Assigned Vehicle'),
                      subtitle: Text(
                        vehicle?['vehicle_number'] ?? 'Unknown',
                      ),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.speed),
                      title: const Text('Vehicle Status'),
                      subtitle: Text(
                        vehicle?['status'] ?? 'Unknown',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: location == null
                          ? const Text(
                              'No GPS data available',
                              style: TextStyle(fontSize: 18),
                            )
                          : Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latitude: ${location!['latitude']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Longitude: ${location!['longitude']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Speed: ${location!['speed']} km/h',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Timestamp: ${location!['timestamp']}',
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Vehicle Map',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  buildMap(),

                  const SizedBox(height: 24),

                  const Text(
                    'GPS History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: history.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No GPS history available'),
                          )
                        : Column(
                            children: history.take(10).map((record) {
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(
                                  '${record['latitude']}, ${record['longitude']}',
                                ),
                                subtitle: Text(
                                  'Speed: ${record['speed']} km/h\n'
                                  'Time: ${record['timestamp']}',
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}