import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import '../screens/multiconsole.dart';

class ConsoleDetailsPage extends StatefulWidget {
  final Console console;

  const ConsoleDetailsPage({super.key, required this.console});

  @override
  State<ConsoleDetailsPage> createState() => _ConsoleDetailsPageState();
}

class _ConsoleDetailsPageState extends State<ConsoleDetailsPage> {
  int? selectedHours;

  int countdown = 180;
  // OTP is now generated dynamically per booking/cash payment
  late Timer timer;

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> _submitBooking(int consoleId, int userId, int hours, double price, String otp) async {
    final url = Uri.parse('https://tgl.inchrist.co.in/console_booking.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'console_id': consoleId,
        'user_id': userId,
        'hours': hours,
        'price': price,
        'otp': otp,
      }),
    );

    if (response.statusCode != 200 || jsonDecode(response.body)['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book console. Please try again.')),
      );
    }
  }

  void _showPaymentOptions(BuildContext context, double totalPrice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF2A004A),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (selectedHours == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a duration before proceeding.')),
                    );
                    return;
                  }
                  String generatedOtp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
                  await _submitBooking(widget.console.id, 1, selectedHours!, totalPrice, generatedOtp);

                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      Navigator.pop(context); // close modal after ensuring context is mounted
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OtpPaymentScreen(
                            otp: generatedOtp,
                            price: totalPrice,
                          ),
                        ),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Pay with Cash"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement K-Net logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Pay with K-Net"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = 0;
    if (selectedHours != null) {
      totalPrice = widget.console.hourlyRates[selectedHours!] ?? 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B0032),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text('Console Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(widget.console.imageUrl, height: 200),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    widget.console.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Select Duration:',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Choose hours and view price:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.0,
                    children: widget.console.hourlyRates.entries.map((entry) {
                      final hrs = entry.key;
                      return _durationPriceButton('${entry.value.toStringAsFixed(2)} KD', hrs);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Description',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Text(
                    widget.console.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                if (selectedHours != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                        ),
                        onPressed: () {
                         _showPaymentOptions(context, totalPrice);
                        },
                        child: Text(
                          'Pay Now • ${totalPrice.toStringAsFixed(2)} KD',
                          style: const TextStyle(color: Colors.black),
                        ),
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

  Widget _durationPriceButton(String priceLabel, int hours) {
    final isSelected = selectedHours == hours;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        children: [
          Text(
            '$hours Hour${hours > 1 ? "s" : ""}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedHours = hours;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.white : Colors.black,
              foregroundColor: isSelected ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class OtpPaymentScreen extends StatefulWidget {
  final String otp;
  final double price;

  const OtpPaymentScreen({super.key, required this.otp, required this.price});

  @override
  State<OtpPaymentScreen> createState() => _OtpPaymentScreenState();
}

class _OtpPaymentScreenState extends State<OtpPaymentScreen> with TickerProviderStateMixin {
  int countdown = 180;
  late Timer timer;

  late AnimationController _beaconController;
  late Animation<double> _beaconAnimation;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        t.cancel();
        _showFailureDialog();
      }
    });

    // Polling check for staff approval every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (t) async {
      if (countdown > 0) {
        final response = await http.post(
          Uri.parse('https://tgl.inchrist.co.in/check_otp_status.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'otp': widget.otp}),
        );

        final res = jsonDecode(response.body);
        if (res['verified'] == true) {
          t.cancel();
          timer.cancel();
          handleOtpVerifiedByStaff();
        }
      } else {
        t.cancel();
      }
    });

    _beaconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _beaconAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _beaconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    _beaconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B0032),
      appBar: AppBar(
        title: const Text("Payment OTP"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.otp[index],
                    style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _beaconAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _beaconAnimation.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: countdown / 180,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
                Text(
                  '$countdown s',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Show this OTP to staff and pay the cash.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Total: ${widget.price.toStringAsFixed(2)} KD',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verification Failed"),
        content: const Text("OTP verification timed out. Please try again."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to console details
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> handleOtpVerifiedByStaff() async {
    final response = await http.post(
      Uri.parse('https://tgl.inchrist.co.in/approve_otp.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'otp': widget.otp}),
    );

    final res = jsonDecode(response.body);
    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Booking Confirmed"),
          content: const Text("Your hours have been approved successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      _showFailureDialog();
    }
  }
}