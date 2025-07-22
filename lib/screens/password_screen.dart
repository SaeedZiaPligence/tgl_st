import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PasswordScreen extends StatefulWidget {
  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter Password',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final args = ModalRoute.of(context)?.settings.arguments as Map?;

                        if (args != null) {
                          final mobile = args['mobile'];
                          final accountType = args['account_type'];
                          final enteredPassword = _passwordController.text.trim();

                          // Dummy staff password check for demonstration
                          if (accountType == 'staff') {
                            if (enteredPassword == 'daniel') {
                              await prefs.setString('mobile', mobile);
                              await prefs.setString('account_type', accountType);
                              Navigator.pushReplacementNamed(context, '/staffDashboard');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Incorrect password for staff')),
                              );
                            }
                          } else {
                            // For users, validate password via API
                            final response = await http.post(
                              Uri.parse('https://tgl.inchrist.co.in/login.php'),
                              body: {
                                'mobile': mobile,
                                'password': enteredPassword,
                                'account_type': accountType,
                              },
                            );
                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              if (data['status'] == 'success') {
                                await prefs.setString('mobile', mobile);
                                await prefs.setString('account_type', accountType);

                                final userResponse = await http.post(
                                  Uri.parse('https://tgl.inchrist.co.in/get_user_details.php'),
                                  body: {'mobile': mobile},
                                );

                                if (userResponse.statusCode == 200) {
                                  final userDetails = json.decode(userResponse.body);
                                  if (userDetails['status'] == 'success') {
                                    print('User Details Response: ${userResponse.body}');
                                    final userData = userDetails['data'] ?? {};
                                    final civilFront = userData['civil_front_path']?.toString().trim() ?? '';
                                    final civilBack = userData['civil_back_path']?.toString().trim() ?? '';

                                    final hasFront = civilFront.isNotEmpty && civilFront.toLowerCase() != 'null';
                                    final hasBack = civilBack.isNotEmpty && civilBack.toLowerCase() != 'null';

                                    if (hasFront || hasBack) {
                                      Navigator.pushReplacementNamed(context, '/home');
                                    } else {
                                      Navigator.pushReplacementNamed(context, '/uploadCivilId', arguments: {
                                        'mobile': mobile,
                                      });
                                    }
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Incorrect password')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Server error')),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        'Submit',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
