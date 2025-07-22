import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsPage extends StatefulWidget {
  final String? userId;
  const TransactionsPage({Key? key, this.userId}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final userId = widget.userId ?? (await SharedPreferences.getInstance()).getString('user_id');
    if (userId == null) {
      throw Exception('User not logged in');
    }
    final response = await Uri.parse('http://tgl.inchrist.co.in/get_topups.php?user_id=$userId').resolveUri(Uri());
    final res = await http.get(response);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32.0, left: 8, right: 8, bottom: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchTransactions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No transactions found.'));
                    }

                    final transactions = snapshot.data!;
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        // Format date as DD MMM YYYY
                        final date = DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now();
                        final formattedDate =
                            '${date.day.toString().padLeft(2, '0')} '
                            '${_monthName(date.month)} '
                            '${date.year}';
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22.0),
                          ),
                          elevation: 0,
                          margin: const EdgeInsets.all(10),
                          color: Colors.white.withOpacity(0.13),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: const Icon(Icons.attach_money, color: Colors.green, size: 32),
                            title: Text(
                              'Top-up #${transaction['id']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                    const SizedBox(width: 5),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.payments, size: 16, color: Colors.white70),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Method: ${transaction['method']}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'KD ${transaction['price']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _monthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month];
}
