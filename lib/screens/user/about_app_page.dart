import 'package:flutter/material.dart';
import '../../theme/user_theme.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.uiTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About App',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.uiTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo / icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.uiPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_laundry_service_rounded,
                size: 52,
                color: context.uiPrimary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Dobbi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.uiPrimary,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 13, color: context.uiTextSecondary),
            ),
            SizedBox(height: 36),

            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: context.uiPrimary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 36),

            // About paragraph
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.uiPrimary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
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
                  color: context.uiTextPrimary,
                  height: 1.75,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),

            Text(
              '© 2025 Dobbi. All rights reserved.',
              style: TextStyle(fontSize: 12, color: context.uiTextHint),
            ),
          ],
        ),
      ),
    );
  }
}
