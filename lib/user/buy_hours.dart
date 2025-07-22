import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BuyHoursScreen extends StatefulWidget {
  final String? userId;
  const BuyHoursScreen({Key? key, this.userId}) : super(key: key);

  @override
  _BuyHoursScreenState createState() => _BuyHoursScreenState();
}

class _BuyHoursScreenState extends State<BuyHoursScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _packages = [];
  BuildContext? safeContext;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final resp = await http.get(Uri.parse('https://tgl.inchrist.co.in/get_packages.php'));
      debugPrint('get_packages response: ${resp.body}');
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body['status'] == 'success') {
          setState(() {
            _packages = List<Map<String, dynamic>>.from(body['data']);
          });
        }
      }
    } catch (e) {
      // handle error if desired
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    safeContext ??= context;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Buy Hours', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.pushNamed(context, '/transactions');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF4A148C),
              Colors.black,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _packages.isEmpty
                  ? const Center(
                      child: Text(
                        'No packages available',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPackages,
                      color: Colors.orangeAccent,
                      backgroundColor: Colors.white,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _packages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final pkg = _packages[index];
                          // Convert string values to numeric types
                          final label = pkg['package_type'] as String;
                          final hours = int.tryParse(pkg['hours'].toString()) ?? 0;
                          final price = double.tryParse(pkg['price'].toString()) ?? 0.0;
                          return _buildHourCard(
                            context,
                            label,
                            hours,
                            price,
                            _showPaymentDialog,
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
  // Add _createOrder function to the _BuyHoursScreenState class
  Future<void> _createOrder(BuildContext context, int userId, int hours, double price, String method) async {
    try {
      final response = await http.post(
        Uri.parse('https://tgl.inchrist.co.in/create_topup.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'hours': hours,
          'price': price,
          'method': method,
        }),
      );

      print('Response code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      try {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          await Future.delayed(Duration(milliseconds: 50));
          await showDialog(
            context: safeContext!,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Order placed successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.popUntil(safeContext!, ModalRoute.withName('/home'));
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          if (!mounted) return;
          await Future.delayed(Duration(milliseconds: 50));
          await showDialog(
            context: safeContext!,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Error'),
                content: Text('Failed: ${data['message']}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        await showDialog(
          context: safeContext!,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Server error or invalid response'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      if (!mounted) return;
      await showDialog(
        context: safeContext!,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showPaymentDialog(BuildContext context, int hours, double price) {
    String selectedMethod = 'Cash';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: Colors.grey.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Pay KD ${price.toStringAsFixed(2)} with:', style: const TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.delayed(Duration(milliseconds: 300), () {
                          if (mounted) {
                            _createOrder(
                              context,
                              (widget.userId != null ? int.tryParse(widget.userId!) ?? 1 : 1),
                              hours,
                              price,
                              'Cash',
                            );
                          }
                        });
                      },
                      child: const Text('Cash', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected K-Net for KD ${price.toStringAsFixed(2)}')),
                        );
                      },
                      child: const Text('K-Net', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected Apple Pay for KD ${price.toStringAsFixed(2)}')),
                        );
                      },
                      child: const Text('Apple Pay', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildHourCard(BuildContext context, String label, int hours, double price, void Function(BuildContext, int, double) showPaymentDialog) {
  return GestureDetector(
    onTap: () => showPaymentDialog(context, hours, price),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: MediaQuery.of(context).size.width / 2 - 24,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A148C), Colors.deepOrangeAccent],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label only
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Pass Type and Buy button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$hours Hours',
                    style: const TextStyle(color: Colors.yellow, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    onPressed: () => showPaymentDialog(context, hours, price),
                    child: const Text('Buy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Price row
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'KD ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}