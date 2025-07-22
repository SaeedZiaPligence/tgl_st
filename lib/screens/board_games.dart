import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';

class BoardGamesScreen extends StatefulWidget {
  const BoardGamesScreen({super.key});

  @override
  State<BoardGamesScreen> createState() => _BoardGamesScreenState();
}

class _BoardGamesScreenState extends State<BoardGamesScreen> {
  late final PageController _controller;
  late final SwipableStackController _swipeController;

  final boardGameImages = [
    'https://therewillbe.games/media/reviews/photos/original/ed/a3/57/cover-your-kingdom-board-game-review-24-1579666775.jpeg',
    'https://cf.geekdo-images.com/c4S2XDRb_DCYCAV-ZAzDpg__opengraph/img/CHXNeOpfS6CCqn8e2pZOs-VlSfA=/0x0:983x516/fit-in/1200x630/filters:strip_icc()/pic288405.jpg',
    'https://lh3.googleusercontent.com/proxy/N61oGFVYryqKBKhDOOFpZrOXYneve7ENT_rWgwOzIRdGLEu7UgW5MI0KEfoCOkPZ7FfYpyv6JRXKlDrszcsWEbF9zMc7qVvSb3g9MpqaZeFMRAJcNgVPoQaX',
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.6);
    _swipeController = SwipableStackController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Your Board Game',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SwipableStack(
                    controller: _swipeController,
                    itemCount: boardGameImages.length,
                    allowVerticalSwipe: false,
                    builder: (context, properties) {
                      final index = properties.index % boardGameImages.length;
                      return Center(
                        child: Container(
                          width: 240,
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(boardGameImages[index]),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Handle board game selection
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Select Game"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}