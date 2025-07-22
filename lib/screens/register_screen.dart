import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  final String mobile;
  const RegisterScreen({super.key, required this.mobile});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final dobController = TextEditingController();
  final civilIdController = TextEditingController();
  String gender = 'male';

  bool _isLoading = false;

  File? _frontImage;
  File? _backImage;

  Future<void> pickImage(bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String formattedDob;
    try {
      formattedDob = DateFormat('yyyy-MM-dd').format(
        DateFormat('dd MMM yyyy').parseStrict(dobController.text),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid date format")));
      setState(() => _isLoading = false);
      return;
    }

    final response = await http.post(
      Uri.parse("https://tgl.inchrist.co.in/register_user.php"),
      body: {
        'mobile': widget.mobile,
        'name': nameController.text,
        'username': usernameController.text,
        'password': passwordController.text,
        'gender': gender,
        'date_of_birth': formattedDob,
        'civil_id': civilIdController.text,
      },
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    setState(() => _isLoading = false);

    final responseData = jsonDecode(response.body);

    if (responseData['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_completed', true);
      Navigator.pushReplacementNamed(context, '/uploadCivilId', arguments: {
        'mobile': widget.mobile,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'] ?? "Registration failed!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      // Removed AppBar as per instruction
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 3.0,
              colors: [
                Color(0xFF4A148C),
                Colors.black,
                Colors.grey,
              ],
              stops: [0.0, 1.5, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "Complete Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter username" : null,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: nameController,
                  builder: (context, TextEditingValue value, _) {
                    final base = value.text.trim().split(' ').join('').toLowerCase();
                    if (base.isEmpty) return const SizedBox.shrink();

                    final keywords = ['gamer', 'ninja', 'shadow', 'pro', 'champ', 'strike', 'blaze', 'hunter'];
                    final suggestions = keywords.map((kw) => "@$base$kw").take(4).toList();

                    return Wrap(
                      spacing: 8,
                      children: suggestions.map((suggestion) {
                        return GestureDetector(
                          onTap: () => usernameController.text = suggestion,
                          child: Chip(
                            label: Text(suggestion, style: const TextStyle(color: Colors.black)),
                            backgroundColor: Colors.blueAccent.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 4 ? "Password too short" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dobController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Date of Birth (YYYY-MM-DD)",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter date of birth" : null,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      dobController.text = DateFormat('dd MMM yyyy').format(pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: civilIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Enter your civil id no",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter Civil ID" : null,
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Text("Gender", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: AssetImage('assets/images/male_avatar.png'),
                              backgroundColor: Colors.transparent,
                            ),
                            SizedBox(width: 6),
                            Text("Male", style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        selected: gender == 'male',
                        selectedColor: Colors.greenAccent,
                        backgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        onSelected: (_) => setState(() => gender = 'male'),
                      ),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: AssetImage('assets/images/female_avatar.png'),
                              backgroundColor: Colors.transparent,
                            ),
                            SizedBox(width: 6),
                            Text("Female", style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        selected: gender == 'female',
                        selectedColor: Colors.greenAccent,
                        backgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        onSelected: (_) => setState(() => gender = 'female'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Submit", style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}