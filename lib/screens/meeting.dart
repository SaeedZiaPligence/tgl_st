import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'addmeeting.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({Key? key}) : super(key: key);

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map>> _allMeetings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _fetchMeetings();
  }

  Future<void> _fetchMeetings() async {
    final url = Uri.parse('https://tgl.inchrist.co.in/get_meetings.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final List<dynamic> data = result['data'];
        Map<DateTime, List<Map>> meetingsMap = {};
        for (var item in data) {
          // Use 'meeting_date' from the API response
          String dateStr = item['meeting_date'] ?? '';
          DateTime? date;
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            continue;
          }
          DateTime dateKey = DateTime.utc(date.year, date.month, date.day);
          if (!meetingsMap.containsKey(dateKey)) {
            meetingsMap[dateKey] = [];
          }
          meetingsMap[dateKey]!.add(item);
        }
        setState(() {
          _allMeetings = meetingsMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map> _getMeetingsForDay(DateTime day) {
    return _allMeetings[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    final now = DateTime.now();

    // Flatten all meetings with their dates for tab views
    List<MapEntry<DateTime, Map>> allMeetingsList = [];
    _allMeetings.forEach((date, meetings) {
      for (var meeting in meetings) {
        allMeetingsList.add(MapEntry(date, meeting));
      }
    });

    List<MapEntry<DateTime, Map>> upcomingMeetings = allMeetingsList.where((entry) => entry.key.isAfter(now) || isSameDay(entry.key, now)).toList();
    List<MapEntry<DateTime, Map>> completedMeetings = allMeetingsList.where((entry) => entry.key.isBefore(now) && !isSameDay(entry.key, now)).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Meetings",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.purple[400],
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.white70),
                ),
                headerStyle: const HeaderStyle(
                  titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.white70),
                  weekdayStyle: TextStyle(color: Colors.white),
                ),
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: _getMeetingsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.deepPurpleAccent,
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Completed"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming Meetings List
                  upcomingMeetings.isEmpty
                      ? Center(child: Text("No upcoming meetings", style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: upcomingMeetings.length,
                          itemBuilder: (context, index) {
                            final entry = upcomingMeetings[index];
                            final meeting = entry.value;
                            final date = entry.key;
                            final title = meeting['title'] ?? 'No Title';
                            final staffList = meeting['staff'] as List<dynamic>? ?? [];
                            final formattedDate = DateFormat('dd-MM-yyyy').format(date);

                            return Card(
                              color: Colors.deepPurple[800],
                              child: ListTile(
                                title: Text(title, style: const TextStyle(color: Colors.white)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formattedDate, style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: staffList.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                                        itemBuilder: (context, i) {
                                          final staff = staffList[i];
                                          final name = staff['name'] ?? '';
                                          final avatarUrl = staff['avatar'] ?? '';
                                          return Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                                backgroundColor: Colors.grey[700],
                                                child: avatarUrl.isEmpty ? Text(name.isNotEmpty ? name[0] : '', style: const TextStyle(color: Colors.white, fontSize: 12)) : null,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  // Completed Meetings List
                  completedMeetings.isEmpty
                      ? Center(child: Text("No completed meetings", style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: completedMeetings.length,
                          itemBuilder: (context, index) {
                            final entry = completedMeetings[index];
                            final meeting = entry.value;
                            final date = entry.key;
                            final title = meeting['title'] ?? 'No Title';
                            final staffList = meeting['staff'] as List<dynamic>? ?? [];
                            final formattedDate = DateFormat('dd-MM-yyyy').format(date);

                            return Card(
                              color: Colors.green[900],
                              child: ListTile(
                                title: Text(title, style: const TextStyle(color: Colors.white)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formattedDate, style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: staffList.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                                        itemBuilder: (context, i) {
                                          final staff = staffList[i];
                                          final name = staff['name'] ?? '';
                                          final avatarUrl = staff['avatar'] ?? '';
                                          return Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                                backgroundColor: Colors.grey[700],
                                                child: avatarUrl.isEmpty ? Text(name.isNotEmpty ? name[0] : '', style: const TextStyle(color: Colors.white, fontSize: 12)) : null,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMeetingPage()),
          );
          if (result == true) {
            _fetchMeetings();
          }
        },
      ),
    );
  }
}
