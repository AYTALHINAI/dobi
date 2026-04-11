import 'package:flutter/material.dart';
import '../../theme/user_theme.dart';

class UserOrdersPage extends StatelessWidget {
  const UserOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Orders',
          style: TextStyle(
            color: context.uiTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: context.uiTextHint,
            ),
            SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.uiTextSecondary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your orders will appear here once you place one.',
              style: TextStyle(fontSize: 13, color: context.uiTextHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
