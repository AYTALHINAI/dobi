import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About App',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo / icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1AE6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_laundry_service_rounded,
                size: 52,
                color: Color(0xFF1A1AE6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dobbi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1AE6),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 36),

            // Divider
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1AE6).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 36),

            // About paragraph
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Dobbi is a smart, on-demand laundry platform designed to make your life easier. '
                'We connect customers with trusted local laundry shops, offering a seamless experience '
                'from scheduling a pickup to receiving freshly cleaned clothes right at your doorstep.\n\n'
                'Whether you need a quick wash, delicate dry cleaning, or heavy-duty laundry, Dobbi '
                'has you covered. Our app gives shop owners powerful tools to manage their services, '
                'track orders, and grow their business — while customers enjoy a simple, transparent, '
                'and reliable laundry service at the tap of a button.\n\n'
                'Built for the Omani community, Dobbi is committed to quality, convenience, and '
                'trust — bringing professional laundry care closer to you, every day.',
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.black87,
                  height: 1.75,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            Text(
              '© 2025 Dobbi. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
