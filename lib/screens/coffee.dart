import 'dart:ui';
import 'package:flutter/material.dart';

class CoffeeBeansScreen extends StatelessWidget {
  const CoffeeBeansScreen({Key? key}) : super(key: key);

  // Example bean and gift products
  final beans = const [
    {
      'name': 'Robusta beans',
      'desc': 'A strong, bold flavor and high caffeine content.',
      'img': 'https://images.pexels.com/photos/302902/pexels-photo-302902.jpeg',
      'price': '15 KD'
    },
    {
      'name': 'Arabica beans',
      'desc': 'Experience a smooth, low acidity flavor in your coffee.',
      'img': 'https://images.pexels.com/photos/209348/pexels-photo-209348.jpeg',
      'price': '12 KD'
    },
  ];
  final gifts = const [
    {
      'name': 'Chocolate doughnut',
      'desc': 'Decadent doughnut to satisfy your sweet tooth.',
      'img': 'https://images.pexels.com/photos/461382/pexels-photo-461382.jpeg',
      'price': '2 KD',
      'old_price': '5 KD'
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Replace with your actual location fetch
    final location = "Kuwait City, Kuwait";

    return Scaffold(
      backgroundColor: Colors.brown[900],
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Color(0xFF59443c),
              Color(0xFF201610),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main scroll content
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                children: [
                  // Top Bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Good morning",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.white70, size: 18),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.brown[200],
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://randomuser.me/api/portraits/men/47.jpg',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  // Tabs (fake, not functional for now)
                  SizedBox(
                    height: 38,
                    child: Row(
                      children: [
                        _tabItem('Classic coffee', false),
                        _tabItem('Coffee beans', true),
                        // _tabItem('Desserts', false),
                        _tabItem('Signature', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Best Choice
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Best choice",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 22)),
                      Text("See more",
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Beans cards
                  SizedBox(
                    height: 260,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: beans.map((bean) {
                          return SizedBox(
                            width: 190,
                            child: _glassCard(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      bean['img']!,
                                      height: 90,
                                      width: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(bean['name']!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(bean['desc']!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(bean['price']!,
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 16)),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.12),
                                        child: const Icon(Icons.arrow_forward,
                                            color: Colors.white),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Gift of flavor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Gift of flavor",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 22)),
                      Text("See more",
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Gift Card
                  ...gifts.map((gift) {
                    return _glassCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              gift['img']!,
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(gift['name']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 3),
                                Text(gift['desc']!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (gift['old_price'] != null)
                                      Text(
                                        gift['old_price']!,
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 14,
                                            decoration:
                                            TextDecoration.lineThrough),
                                      ),
                                    const SizedBox(width: 6),
                                    Text(gift['price']!,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.13),
                            child: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
              // Glassy Bottom Nav Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        color: Colors.white.withOpacity(0.10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _navIcon(Icons.whatshot, "Popular", false),
                            _navIcon(Icons.home, "Home", true),
                            _navIcon(Icons.favorite, "Favorites", false),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Glass card for sections
  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.13),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _tabItem(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  letterSpacing: 0.2)),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
            )
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: selected ? Colors.white : Colors.white70, size: 30),
        Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70, fontSize: 13))
      ],
    );
  }
}