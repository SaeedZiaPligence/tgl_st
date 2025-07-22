import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  final String? userId;
  const HomeScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>> _topUpsFuture = Future.value([]);
  late Future<void> _loadDataFuture;
  String _userName = '';
  String _username = '';
  String _profileImageUrl = '';
  String _gender = '';
  String _dob = '';
  String _userId = '';

  int _hours = 0;
  // Fetch top-up transactions and return data only
  Future<List<Map<String, dynamic>>> _fetchTopUps() async {
    if (_userId.isEmpty) return [];

    print('Fetching top-ups for user ID: $_userId');
    final uri = Uri.parse('https://tgl.inchrist.co.in/get_topups.php?user_id=$_userId');
    final response = await http.get(uri);
    print('Top-ups API response: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        final data = List<Map<String, dynamic>>.from(result['data'])
            .where((txn) => txn['method']?.toLowerCase() == 'topup')
            .toList();
        print('Top-ups fetched: $data');
        return data;
      }
    }
    return [];
  }
  DateTime _lastTopUpDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _topUpsFuture = Future.value([]); // default fallback
    _loadCachedUserDetails().then((_) async {
      if (_userId.isNotEmpty) {
        final topUps = await _fetchTopUps();

        int totalHours = 0;
        if (topUps.isNotEmpty) {
          _lastTopUpDate = DateTime.parse(topUps.first['created_at']);
          for (var txn in topUps) {
            totalHours += int.tryParse(txn['hours'].toString()) ?? 0;
          }
        }

        setState(() {
          _hours = totalHours;
          _topUpsFuture = Future.value(topUps);
        });
      }
    });
    _loadDataFuture = _loadData();
    _fetchUserDetails();
  }

  Future<void> _loadData() async {
    // This can be used for pull-to-refresh logic
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadCachedUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? '';
      _username = prefs.getString('username') ?? '';
      _gender = prefs.getString('gender') ?? '';
      final tempUserId = prefs.getString('user_id') ?? '';
      // Use widget.userId if provided and not empty, otherwise fallback to prefs
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        _userId = widget.userId!;
      } else {
        _userId = tempUserId;
      }
      final rawDob = prefs.getString('date_of_birth') ?? '';
      if (rawDob.isNotEmpty) {
        try {
          final dobDate = DateTime.parse(rawDob);
          final formatted = DateFormat('dd MMM yyyy').format(dobDate);
          final now = DateTime.now();
          int age = now.year - dobDate.year;
          if (now.month < dobDate.month || (now.month == dobDate.month && now.day < dobDate.day)) {
            age--;
          }
          _dob = '$formatted ($age yrs)';
        } catch (e) {
          _dob = rawDob;
        }
      }
    });
    // Removed fetching top-ups and setState here
  }

  Future<void> _fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobile') ?? '';
    if (mobile.isEmpty) return;
    final response = await http.post(
      Uri.parse('https://tgl.inchrist.co.in/get_user_details.php'),
      body: {'mobile': mobile},
    );
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        final data = result['data'];
        await prefs.setString('name', data['name'] ?? '');
        await prefs.setString('username', data['username'] ?? '');
        await prefs.setString('gender', data['gender'] ?? '');
        await prefs.setString('date_of_birth', data['date_of_birth'] ?? '');
        // Refresh UI with updated values
        _loadCachedUserDetails();
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/onboard');
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.pushNamed(context, '/food');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/coffee');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _userName.isNotEmpty ? 'Welcome, $_userName' : 'Home',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          )
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A148C),
                Colors.black,
                Color(0xFF1A1A1A),
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A148C),
              Colors.black,
              Color(0xFF1A1A1A),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8E2DE2),
                            Color(0xFFFFA500),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: _profileImageUrl.isNotEmpty
                                ? NetworkImage(_profileImageUrl)
                                : const AssetImage('assets/images/male_avatar.png') as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _userName.isNotEmpty ? _userName : 'User',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Hours: $_hours',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, ),
                                    ),
                                  ],
                                ),
                                if (_username.isNotEmpty)
                                  Text('$_username',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 6),
                                Text('Gender: $_gender', style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Date of Birth: $_dob',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 20),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Last Top-up: ${DateFormat('dd MMM yyyy').format(_lastTopUpDate)}',
                                        style: const TextStyle(color: Colors.yellow),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 0,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildFeatureCard('Buy Hours', Icons.access_time),
                          _buildFeatureCard('Consoles', Icons.sports_esports),
                          _buildFeatureCard('Board Games', Icons.extension),
                          _buildFeatureCard('Library', Icons.menu_book),
                          _buildFeatureCard('Tournaments', Icons.emoji_events),
                          _buildFeatureCard('Services', Icons.build),
                          _buildFeatureCard('Merchandise', Icons.store),
                          _buildFeatureCard('The Museum', Icons.museum),
                          _buildFeatureCard('Shooting Area', Icons.sports_martial_arts),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top-up Transactions',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _topUpsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No transactions found', style: TextStyle(color: Colors.white)),
                                );
                              }

                              final transactions = snapshot.data!;
                              return SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  itemCount: transactions.length,
                                  itemBuilder: (context, index) {
                                    final txn = transactions[index];
                                    final date = DateTime.tryParse(txn['created_at']) ?? DateTime.now();
                                    final formattedDate = DateFormat('dd MMM yyyy').format(date);
                                    return Card(
                                      color: Colors.deepPurple,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: ListTile(
                                        leading: const Icon(Icons.access_time, color: Colors.white),
                                        title: Text('${txn['hours']} Hours', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                          'Payment: ${txn['method']} • Status: ${txn['status']}',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('${txn['price']} KD', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Food'),
                  BottomNavigationBarItem(icon: Icon(Icons.local_cafe), label: 'Coffee'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String label, IconData icon) {
    String imagePath;
    switch (label) {
      case 'Buy Hours':
        imagePath = 'assets/images/buy.png';
        break;
      case 'Consoles':
        imagePath = 'assets/images/consoles.png';
        break;
      case 'Board Games':
        imagePath = 'assets/images/dice.png';
        break;
      case 'Library':
        imagePath = 'assets/images/library.png';
        break;
      case 'Tournaments':
        imagePath = 'assets/images/match.png';
        break;
      case 'Services':
        imagePath = 'assets/images/service.png';
        break;
      case 'Merchandise':
        imagePath = 'assets/images/merchandise.png';
        break;
      case 'The Museum':
        imagePath = 'assets/images/museum.png';
        break;
      case 'Shooting Area':
        imagePath = 'assets/images/shooting.png';
        break;
      default:
        imagePath = 'assets/images/default.png';
    }

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      child: Card(
        color: Colors.deepPurple[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            if (label == 'Buy Hours') {
              Navigator.pushNamed(context, '/buy_hours');
            } else if (label == 'The Museum') {
              Navigator.pushNamed(context, '/museum');
            } else if (label == 'Library') {
              Navigator.pushNamed(context, '/library');
            } else if (label == 'Consoles') {
              Navigator.pushNamed(context, '/console');
            }
            // Add more navigation logic as needed
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(imagePath, height: 40, width: 40, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  }