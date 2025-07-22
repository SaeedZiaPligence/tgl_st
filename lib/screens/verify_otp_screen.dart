import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerifyOtpScreen extends StatefulWidget {
  final String mobile;
  const VerifyOtpScreen({super.key, required this.mobile});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());
  bool _isVerifying = false;

  int _secondsRemaining = 30;
  bool _resendEnabled = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 30;
    _resendEnabled = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _resendEnabled = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter 4-digit OTP")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    final response = await http.post(
      Uri.parse("https://tgl.inchrist.co.in/verify_otp.php"),
      body: {
        'mobile': widget.mobile,
        'otp': otp,
      },
    );

    final result = jsonDecode(response.body);
    setState(() => _isVerifying = false);

    if (result['status'] == 'verified') {
      if (result['account_type'] == 'new') {
        Navigator.pushNamed(context, '/register', arguments: {'mobile': widget.mobile});
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
    }
  }

  void resendOtp() async {
    setState(() {
      _resendEnabled = false;
      _secondsRemaining = 30;
    });
    _startCountdown();

    final response = await http.post(
      Uri.parse("https://tgl.inchrist.co.in/send_otp.php"),
      body: {'mobile': widget.mobile},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP resent")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to resend OTP")),
      );
    }
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Verify OTP", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _otpControllers[index],
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            _isVerifying
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
              onPressed: verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Verify", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            _resendEnabled
              ? ElevatedButton(
                  onPressed: resendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade100,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Resend OTP", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : Text(
                  "Resend in $_secondsRemaining s",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
          ],
        ),
      ),
    ));
  }
}