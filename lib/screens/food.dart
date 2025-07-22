import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  bool _locationAllowed = false;
  bool _loadingLocation = true;
  double? _lastLat;
  double? _lastLng;
  double? _lastDistance;
  String? _lastAddress;
  bool _locationToggle = true;
  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoading = true;

  List<Map<String, dynamic>> _banners = [];
  bool _bannersLoading = true;

  Future<void> _fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('https://tgl.inchrist.co.in/get_banners.php'),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _banners = List<Map<String, dynamic>>.from(result['banners']);
            _bannersLoading = false;
          });
        } else {
          setState(() {
            _bannersLoading = false;
          });
        }
      } else {
        setState(() {
          _bannersLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _bannersLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://tgl.inchrist.co.in/get_food_categories.php'),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(result['categories']);
            _categoriesLoading = false;
          });
        } else {
          setState(() {
            _categoriesLoading = false;
          });
        }
      } else {
        setState(() {
          _categoriesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchBanners();
    _checkLocation();
  }

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _checkLocation() async {
    try {
      final pos = await _getCurrentLocation(context).timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (pos == null) {
        setState(() {
          _locationAllowed = false;
          _loadingLocation = false;
        });
        _showLocationErrorDialog();
        return;
      }
      // Allowed center and radius (in km)
      const centerLat = 29.331493849011906;
      const centerLng = 48.01028127696158;
      const allowedRadiusKm = 3.0;

      double distance = _calculateDistance(
        pos.latitude,
        pos.longitude,
        centerLat,
        centerLng,
      );

      print("User lat: ${pos.latitude}, lng: ${pos.longitude}");
      print("Center lat: $centerLat, lng: $centerLng");
      print("Calculated distance: $distance km");

      bool allowed = distance <= allowedRadiusKm;

      setState(() {
        _locationAllowed = allowed;
        _loadingLocation = false;
        _lastLat = pos.latitude;
        _lastLng = pos.longitude;
        _lastDistance = distance;
      });

      if (pos.latitude != null && pos.longitude != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            setState(() {
              _lastAddress = [
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
                place.country
              ].where((element) => element != null && element.isNotEmpty).join(", ");
            });
          }
        } catch (_) {
          setState(() {
            _lastAddress = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _locationAllowed = false;
        _loadingLocation = false;
      });
      _showLocationErrorDialog();
    }
  }

  double _calculateDistance(
    double userLat,
    double userLng,
    double centerLat,
    double centerLng,
  ) {
    const double earthRadius = 6371; // km
    double dLat = (centerLat - userLat) * pi / 180;
    double dLon = (centerLng - userLng) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * pi / 180) *
            cos(centerLat * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    return distance;
  }

  void _showLocationErrorDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Location Error"),
          content: const Text("We couldn't fetch your location. Please check location services and permissions."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget toggleSwitch() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Location Lock:', style: TextStyle(color: Colors.white)),
            Switch(
              value: _locationToggle,
              onChanged: (value) {
                setState(() {
                  _locationToggle = value;
                });
              },
              activeColor: Colors.limeAccent,
            ),
          ],
        ),
      );
    }
    if (_locationToggle && _loadingLocation) {
      return Scaffold(
        body: Column(
          children: [
            toggleSwitch(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Color(0xFF4A148C),
                      Colors.black,
                      Colors.grey,
                    ],
                    stops: [0.0, 1.5, 1.0],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.limeAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_locationToggle && !_locationAllowed) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Color(0xFF4A148C),
                      Colors.black,
                      Colors.grey,
                    ],
                    stops: [0.0, 1.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Expanded(
                            child: Text(
                              "Not Serving",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      // Move toggleSwitch() here, just after the Row and before SizedBox(height: 8)
                      toggleSwitch(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Sorry! You are too far from the Gaming Hub.",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              if (_lastAddress != null)
                                Text(
                                  "Your location: $_lastAddress",
                                  style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              if (_lastDistance != null)
                                Text(
                                  "Distance to TGH: ${_lastDistance!.toStringAsFixed(3)} km",
                                  style: const TextStyle(fontSize: 13, color: Colors.yellow),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                                icon: const Icon(Icons.directions, color: Colors.white),
                                label: const Text(
                                  'Show Directions to TGH',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  const tghLat = 29.331493849011906;
                                  const tghLng = 48.01028127696158;
                                  final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$tghLat,$tghLng');
                                  if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Could not open Google Maps")),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Visit TGH to enjoy the best dishes!",
                                style: TextStyle(fontSize: 14, color: Colors.white54),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Place all the existing FoodScreen build content below this line
    return Scaffold(
      backgroundColor: const Color(0xfff7f7fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text("Location", style: TextStyle(color: Colors.grey, fontSize: 14)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_on, color: Colors.green, size: 18),
                SizedBox(width: 2),
                Text(
                  "The Gaming Hub",
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _categoriesLoading = true;
          });
          await _fetchCategories();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Toggle switch for location lock
            Builder(
              builder: (context) {
                // Use a dark background for toggle to match location screens
                return Container(
                  color: Colors.deepPurple[900],
                  child: toggleSwitch(),
                );
              },
            ),
            bannersCarousel(),
            categoriesRow(),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('See More', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            // Recommended list
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.72,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                _foodCard(
                  img: 'https://images.pexels.com/photos/461382/pexels-photo-461382.jpeg',
                  title: 'Golden Spicy Chicken',
                  desc: 'Indulge in our succulent golden spicy chicken.',
                  price: '5.00',
                  fav: true,
                ),
                _foodCard(
                  img: 'https://images.pexels.com/photos/1639563/pexels-photo-1639563.jpeg',
                  title: 'Cheese Burger Nagi',
                  desc: 'Burger with patty filled with cheese and spices.',
                  price: '4.50',
                  fav: false,
                ),
                _foodCard(
                  img: 'https://images.pexels.com/photos/461382/pexels-photo-461382.jpeg',
                  title: 'Veggie Delight',
                  desc: 'A healthy bowl with fresh vegetables.',
                  price: '3.00',
                  fav: false,
                ),
                _foodCard(
                  img: 'https://images.pexels.com/photos/2232/vegetables-italian-pizza-restaurant.jpg',
                  title: 'Italian Pizza',
                  desc: 'Classic Italian pizza loaded with cheese.',
                  price: '7.00',
                  fav: true,
                ),
                _foodCard(
                  img: 'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg',
                  title: 'French Fries',
                  desc: 'Crispy golden fries served hot.',
                  price: '2.00',
                  fav: false,
                ),
                _foodCard(
                  img: 'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg',
                  title: 'Grilled Sandwich',
                  desc: 'Grilled to perfection, filled with veggies.',
                  price: '3.50',
                  fav: false,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: ''),
        ],
      ),
    );
  }

  Widget bannersCarousel() {
    if (_bannersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 170,
      child: PageView.builder(
        itemCount: _banners.length,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: NetworkImage(banner['image_url'] ?? ''),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                        Text(
                          banner['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (banner['subtitle'] != null && banner['subtitle'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            banner['subtitle'],
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      if (banner['button_text'] != null && banner['button_text'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.limeAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () {
                              // For now, try to launch as URL if action looks like one
                              final action = banner['button_action'];
                              if (action != null && action.toString().startsWith('http')) {
                                launchUrl(Uri.parse(action), mode: LaunchMode.externalApplication);
                              }
                              // Otherwise handle route navigation here if desired
                            },
                            child: Text(
                              banner['button_text'],
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryItem(String name, String iconUrl) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 5,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Center(child: Image.network(iconUrl, width: 36, height: 36)),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }

  Widget _foodCard({
    required String img,
    required String title,
    required String desc,
    required String price,
    bool fav = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(img, width: double.infinity, height: 80, fit: BoxFit.cover),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? Colors.red : Colors.grey[400],
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KD $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.limeAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget categoriesRow() {
    if (_categoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_categories.isEmpty) {
      return const Center(child: Text('No categories found', style: TextStyle(color: Colors.black54)));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _categoryItem(
              cat['name'],
              cat['icon_url'] ?? 'https://via.placeholder.com/48',
            ),
          );
        }).toList(),
      ),
    );
  }
}