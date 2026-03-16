import 'package:flutter/material.dart';

class VehicleRegistrationScreen extends StatelessWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF0),
      appBar: AppBar(
        title: const Text('Vehicle Registration'),
      ),
      body: const Center(
        child: Text(
          'Vehicle registration screen coming soon',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF44526A),
          ),
        ),
      ),
    );
  }
}

