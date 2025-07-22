import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadCivilIdScreen extends StatefulWidget {
  final String mobile;

  const UploadCivilIdScreen({super.key, required this.mobile});

  @override
  State<UploadCivilIdScreen> createState() => _UploadCivilIdScreenState();
}

class _UploadCivilIdScreenState extends State<UploadCivilIdScreen> {
  bool _isUploading = false;
  File? _frontImage;
  File? _backImage;

  @override
  void initState() {
    super.initState();
    _checkCivilIdStatus();
  }

  Future<void> _checkCivilIdStatus() async {
    final response = await http.post(
      Uri.parse('https://tgl.inchrist.co.in/get_user_details.php'),
      body: {'mobile': widget.mobile},
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        final front = (result['data']['civil_front_path'] ?? '').toString().trim();
        final back = (result['data']['civil_back_path'] ?? '').toString().trim();

        print('Fetched Civil Front: "$front"');
        print('Fetched Civil Back: "$back"');

        final isFrontValid = front.isNotEmpty && front.toLowerCase() != 'null';
        final isBackValid = back.isNotEmpty && back.toLowerCase() != 'null';

        if (isFrontValid || isBackValid) {
          print('Valid civil ID found, redirecting to /home');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print('No valid civil ID found, stay on this screen');
        }
      }
    } else {
      print('API call failed with status: ${response.statusCode}');
    }
  }

  Future<void> _pickImage(bool isFront) async {
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

  void _submitImages() async {
    if (_frontImage == null && _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least one image")),
      );
      return;
    }

    setState(() => _isUploading = true);

    final uri = Uri.parse("https://tgl.inchrist.co.in/upload_civil_id.php");
    final request = http.MultipartRequest('POST', uri);
    request.fields['mobile'] = widget.mobile;

    try {
      if (_frontImage != null) {
        request.files.add(await http.MultipartFile.fromPath('civil_front', _frontImage!.path));
      }
      if (_backImage != null) {
        request.files.add(await http.MultipartFile.fromPath('civil_back', _backImage!.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = jsonDecode(responseBody);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Upload successful")),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Upload failed")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server error during upload")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            const Text(
              "Upload Civil ID",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _pickImage(true),
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Front Copy"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _pickImage(false),
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Back Copy"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 24),
            if (_frontImage != null || _backImage != null)
              Row(
                children: [
                  if (_frontImage != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Remove Image?"),
                              content: const Text("Do you want to remove the front image?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _frontImage = null);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("Remove"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Image.file(_frontImage!, height: 120),
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (_backImage != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Remove Image?"),
                              content: const Text("Do you want to remove the back image?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _backImage = null);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("Remove"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Image.file(_backImage!, height: 120),
                      ),
                    ),
                ],
              ),
            const Spacer(),
            _isUploading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ElevatedButton(
                    onPressed: _submitImages,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    child: const Text("Submit"),
                  ),
          ],
        ),
      ),
    );
  }
}