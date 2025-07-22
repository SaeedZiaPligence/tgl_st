import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobile');
    final accountType = prefs.getString('account_type');

    if (mobile != null && accountType != null) {
      Future.delayed(Duration.zero, () {
        if (accountType == 'user') {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (accountType == 'staff') {
          Navigator.pushReplacementNamed(context, '/staffDashboard');
        }
      });
    }
  }

  void sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final checkResponse = await http.post(
        Uri.parse("https://tgl.inchrist.co.in/login.php"),
        body: {'mobile': _mobileController.text},
      );

      setState(() {
        _isLoading = false;
      });

      if (checkResponse.statusCode == 200 && checkResponse.body.trim().startsWith('{')) {
        final result = jsonDecode(checkResponse.body);

        if (result['status'] == 'exists') {
          Navigator.pushNamed(context, '/password', arguments: {
            'mobile': _mobileController.text,
            'account_type': result['user_type'],
          });
        } else if (result['status'] == 'new' && result['user_type'] == 'none') {
          final otpResponse = await http.post(
            Uri.parse("https://tgl.inchrist.co.in/send_otp.php"),
            body: {'mobile': _mobileController.text},
          );
          print("OTP Response: ${otpResponse.body}");

          if (otpResponse.statusCode == 200 && otpResponse.body.trim().startsWith('{')) {
            final otpResult = jsonDecode(otpResponse.body);
            if (otpResult['status'] == 'otp_sent') {
              print("Navigating to verify screen...");
              Navigator.pushNamed(context, '/verify', arguments: {
                'mobile': _mobileController.text,
                'account_type': 'user',
              });
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(otpResult['message'] ?? "OTP send failed")),
              );
            }
          } else {
            print("Unexpected OTP response: ${otpResponse.body}");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("OTP sending failed")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Login failed")),
          );
        }
      } else {
        print("Unexpected response: ${checkResponse.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected server response")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Exception during sendOtp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error sending OTP")),
      );
    }
  }

  void _register() {
    Navigator.pushNamed(context, '/register'); // Create /register route if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        "+965",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: "Enter Mobile Number",
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Send Verification Text", style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 18),),
                      ),
                // TextButton(
                //   onPressed: _register,
                //   child: const Text("Don't have an account? Register"),
                // ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/onboard');
                  },
                  child: const Text(
                    "Back",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}