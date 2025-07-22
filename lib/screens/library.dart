import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> bookCovers = [
      'https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcT8Z35SRMRvA2MMyjfjPdIhs7LsV7bLLplVCi8EdhS64R6aGfDW',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTc3HwaPLLf_tFJiBWCdNd9Gxxp5L9F4VDSlVN3s9ApPBG-qpL2',
      'https://m.media-amazon.com/images/I/71gaMU18K6L._AC_UF1000,1000_QL80_.jpg',
      'https://i.ebayimg.com/images/g/9HUAAOSwEB1m86Kr/s-l1200.jpg',
      'https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcRH5Z0os00cyiC4trR9hxGcl0cA6_Iijkr2n8T1uBU5myRkEstl',
      'https://m.media-amazon.com/images/I/51s2pqNlppL._AC_UF1000,1000_QL80_.jpg',
      'https://m.media-amazon.com/images/I/81aHtpqtNrL._AC_UF1000,1000_QL80_.jpg',
      'https://m.media-amazon.com/images/I/51NOeqzK96L._AC_UF1000,1000_QL80_.jpg',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRhmwNte2bUTSevP8tFjLV4bQWAVyEhARrYirUcpGQbuQYA9aop',
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'The Gaming Library',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(3, (shelfIndex) {
                    final booksPerShelf = 3;
                    final start = shelfIndex * booksPerShelf;
                    final end = (start + booksPerShelf) > bookCovers.length
                        ? bookCovers.length
                        : start + booksPerShelf;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: bookCovers
                                  .sublist(start, end)
                                  .map((url) => Material(
                                    elevation: 10,
                                    borderRadius: BorderRadius.circular(6),
                                    shadowColor: Colors.black45,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        url,
                                        width: 80,
                                        height: 110,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 0),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 22,
                            child: Image.asset(
                              'assets/images/glass.png',
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
          ),
        ),
      ),
    ));
  }
}