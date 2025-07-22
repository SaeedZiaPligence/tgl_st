import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AddMeetingPage extends StatefulWidget {
  const AddMeetingPage({Key? key}) : super(key: key);

  @override
  State<AddMeetingPage> createState() => _AddMeetingPageState();
}

class _AddMeetingPageState extends State<AddMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String location = '';
  DateTime? meetingDate;
  TimeOfDay? meetingTime;
  List<dynamic> staffList = [];
  Set<int> selectedStaffIds = {};

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    final response = await http.get(Uri.parse('https://tgl.inchrist.co.in/get_staff.php'));
    if (response.statusCode == 200) {
      setState(() {
        staffList = json.decode(response.body)['data'];
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        meetingDate != null &&
        meetingTime != null &&
        selectedStaffIds.isNotEmpty) {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(meetingDate!);
      final String formattedTime =
          '${meetingTime!.hour.toString().padLeft(2, '0')}:${meetingTime!.minute.toString().padLeft(2, '0')}:00';

      final String staffIds = selectedStaffIds.join(',');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Step 1: Save meeting
      final addMeetingResp = await http.post(
        Uri.parse('https://tgl.inchrist.co.in/add_meeting.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
          'location': location,
          'meeting_date': formattedDate,
          'meeting_time': formattedTime,
          'staff_ids': staffIds,
        }),
      );

      if (addMeetingResp.statusCode == 200) {
        final addMeetingResult = json.decode(addMeetingResp.body);
        if (addMeetingResult['status'] == 'success' && addMeetingResult['meeting_id'] != null) {
          // Step 2: Notify staff via WhatsApp
          final notifyResp = await http.post(
            Uri.parse('https://tgl.inchrist.co.in/notify.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'meeting_id': addMeetingResult['meeting_id']}),
          );

          Navigator.of(context).pop(); // Remove loading

          if (notifyResp.statusCode == 200) {
            final notifyResult = json.decode(notifyResp.body);
            String msg;
            if (notifyResult['status'] == 'success') {
              msg = 'Meeting saved and WhatsApp sent!';
            } else if (notifyResult['status'] == 'partial') {
              msg = 'Meeting saved. Some WhatsApp messages failed.';
            } else {
              msg = notifyResult['message'] ?? 'Failed to send WhatsApp notification.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
            if (notifyResult['status'] == 'success' || notifyResult['status'] == 'partial') {
              if (mounted) Navigator.pop(context, true);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meeting saved, but failed to notify staff!')),
            );
          }
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(addMeetingResult['message'] ?? 'Failed to save meeting')),
          );
        }
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Add Meeting",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // To balance the row
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        CupertinoTextField(
                          placeholder: 'Title',
                          style: const TextStyle(color: Colors.white),
                          placeholderStyle: const TextStyle(color: Colors.white54),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (v) => title = v,
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          placeholder: 'Description',
                          style: const TextStyle(color: Colors.white),
                          placeholderStyle: const TextStyle(color: Colors.white54),
                          padding: const EdgeInsets.all(14),
                          maxLines: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (v) => description = v,
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          placeholder: 'Location',
                          style: const TextStyle(color: Colors.white),
                          placeholderStyle: const TextStyle(color: Colors.white54),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (v) => location = v,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            DateTime now = DateTime.now();
                            DateTime today = DateTime(now.year, now.month, now.day);
                            DateTime initial = meetingDate ?? today;
                            if (initial.isBefore(today)) initial = today;
                            DateTime tempPicked = initial;

                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (BuildContext context) {
                                return Container(
                                  height: 260,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                  ),
                                  child: CupertinoTheme(
                                    data: CupertinoThemeData(
                                      brightness: Brightness.dark,
                                      textTheme: CupertinoTextThemeData(
                                        pickerTextStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.date,
                                      initialDateTime: initial,
                                      minimumDate: today,
                                      maximumYear: 2030,
                                      onDateTimeChanged: (dt) {
                                        tempPicked = dt;
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                            setState(() {
                              meetingDate = tempPicked;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  meetingDate == null
                                      ? 'Select Date'
                                      : 'Date: ${DateFormat('dd MMM yyyy').format(meetingDate!)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.calendar_today, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            TimeOfDay tempTime = meetingTime ?? TimeOfDay.now();
                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (BuildContext context) {
                                return Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                  ),
                                  child: CupertinoTheme(
                                    data: CupertinoThemeData(
                                      brightness: Brightness.dark,
                                      textTheme: CupertinoTextThemeData(
                                        pickerTextStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                    child: CupertinoTimerPicker(
                                      mode: CupertinoTimerPickerMode.hm,
                                      initialTimerDuration: Duration(
                                        hours: meetingTime?.hour ?? 12,
                                        minutes: meetingTime?.minute ?? 0,
                                      ),
                                      onTimerDurationChanged: (Duration d) {
                                        tempTime = TimeOfDay(hour: d.inHours, minute: d.inMinutes % 60);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                            setState(() {
                              meetingTime = tempTime;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  meetingTime == null
                                      ? 'Select Time'
                                      : 'Time: ${meetingTime!.format(context)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.access_time, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Assign to Staff:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: [
                            ...staffList.map((staff) {
                              return ChoiceChip(
                                selected: selectedStaffIds.contains(staff['id']),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedStaffIds.add(staff['id']);
                                    } else {
                                      selectedStaffIds.remove(staff['id']);
                                    }
                                  });
                                },
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    staff['gender'] == 'male' ? Icons.male : Icons.female,
                                    color: staff['gender'] == 'male' ? Colors.blue : Colors.pink,
                                  ),
                                ),
                                label: Text(staff['name'], style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.deepPurple,
                                selectedColor: Colors.green,
                              );
                            }).toList()
                          ],
                        ),
                        const SizedBox(height: 24),
                        CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(12),
                          child: const Text('Save Meeting', style: TextStyle(color: Colors.white)),
                          onPressed: _submit,
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
    );
  }
}