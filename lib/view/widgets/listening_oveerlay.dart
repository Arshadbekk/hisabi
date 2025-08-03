import 'package:flutter/material.dart';

class ListeningOverlay extends StatefulWidget {
  const ListeningOverlay({Key? key}) : super(key: key);

  @override
  _ListeningOverlayState createState() => _ListeningOverlayState();
}

class _ListeningOverlayState extends State<ListeningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // semi-transparent backdrop
        Positioned.fill(
          child: Container(color: Colors.black54),
        ),
        // center content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: _pulse.value,
                  child: child,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(Icons.mic, size: 48, color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Listening…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
