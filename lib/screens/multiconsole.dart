import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../user/ConsoleDetailsPage.dart';

class MultiConsoleScreen extends StatefulWidget {
  const MultiConsoleScreen({super.key});

  @override
  State<MultiConsoleScreen> createState() => _MultiConsoleScreenState();
}

class _MultiConsoleScreenState extends State<MultiConsoleScreen> {
  late final PageController _controller;
  List<Console> consoles = [];
  bool isLoading = true;
  String errorMessage = '';
  double currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.6);
    fetchConsoles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to fetch consoles from the API
  Future<void> fetchConsoles() async {
    final url = Uri.parse('https://tgl.inchrist.co.in/get_consoles.php'); // Replace with your API URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            consoles = (data['data'] as List).map((item) => Console.fromJson(item)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No consoles found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load consoles';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF4A148C), // dark purple
              Colors.black,
              Colors.grey,
            ],
            stops: [0.0, 1.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Select Your Console',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            setState(() {
                              currentPage = _controller.page ?? 0;
                            });
                          }
                          return true;
                        },
                        child: PageView.builder(
                          itemCount: consoles.length,
                          controller: _controller,
                          itemBuilder: (context, index) {
                            final distance = (index - currentPage).abs();
                            final isCentered = distance < 0.5;

                            return Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.only(
                                  top: isCentered ? 8 : 24,
                                  bottom: isCentered ? 24 : 8,
                                ),
                                child: Transform.scale(
                                  scale: isCentered ? 1.2 : 0.85,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Opacity(
                                        opacity: isCentered ? 1.0 : 0.3,
                                        child: Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            image: DecorationImage(
                                              image: NetworkImage(consoles[index].imageUrl),
                                              fit: BoxFit.cover,
                                              colorFilter: isCentered
                                                  ? null
                                                  : const ColorFilter.mode(Colors.black26, BlendMode.darken),
                                            ),
                                            boxShadow: [
                                              if (isCentered)
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.4),
                                                  blurRadius: 20,
                                                  offset: Offset(0, 10),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        consoles[index].name,
                                        style: TextStyle(
                                          fontSize: isCentered ? 18 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(isCentered ? 1.0 : 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 124),
                child: ElevatedButton(
                  onPressed: () {
                    final selectedIndex = currentPage.round().clamp(0, consoles.length - 1);
                    final selectedConsole = consoles[selectedIndex];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsoleDetailsPage(console: selectedConsole),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Select Console", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Console {
  final int id;
  final String name;
  final String imageUrl;
  final String createdAt;
  final String description;
  final double price;
  final Map<int, double> hourlyRates;

  Console({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.description,
    required this.price,
    required this.hourlyRates,
  });

  factory Console.fromJson(Map<String, dynamic> json) {
    Map<int, double> parsedRates = {};
    if (json['hourlyRates'] != null && json['hourlyRates'] is Map<String, dynamic>) {
      json['hourlyRates'].forEach((key, value) {
        parsedRates[int.tryParse(key) ?? 0] = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
      });
    }

    return Console(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      imageUrl: (json['image_url'] != null && json['image_url'].toString().isNotEmpty)
          ? json['image_url']
          : 'https://picsum.photos/200/300?random=${json['id']}',
      createdAt: json['created_at'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      hourlyRates: parsedRates,
    );
  }
}
