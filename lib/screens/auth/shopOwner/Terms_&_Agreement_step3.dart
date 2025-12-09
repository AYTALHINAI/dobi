import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import 'shop_owner_registration_model.dart';
import '../../../../database.dart'; // ← import DatabaseService

class ShopOwnerStep3Terms extends StatefulWidget {
  final ShopOwnerRegistrationData data;
  const ShopOwnerStep3Terms({super.key, required this.data});

  @override
  State<ShopOwnerStep3Terms> createState() => _ShopOwnerStep3TermsState();
}

class _ShopOwnerStep3TermsState extends State<ShopOwnerStep3Terms> {
  bool agreed = false;
  bool isLoading = false;
  final DatabaseService dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    agreed = widget.data.agreedToTerms;
  }

  void showNotification(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> submitApplication() async {
    setState(() => isLoading = true);
    widget.data.agreedToTerms = agreed;

    try {
      String? result = await dbService.registerShopOwner(widget.data);
      if (result == null) {
        showNotification("Application submitted successfully!", color: Colors.green);
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        showNotification(result);
      }
    } catch (e) {
      showNotification("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey.shade300.withOpacity(0.9)),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Step 3: Terms & Agreement",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Review and submit your application",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text("Terms & Conditions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: const Text(
                                "1. Your shop information must be accurate.\n"
                                    "2. You agree to comply with our platform rules.\n"
                                    "3. Submitting false information may result in rejection.\n"
                                    "4. By submitting, you consent to our terms of service.\n",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: agreed,
                                onChanged: (val) {
                                  setState(() => agreed = val ?? false);
                                },
                              ),
                              const Expanded(
                                child: Text("I agree to the terms and conditions", style: TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: agreed && !isLoading ? submitApplication : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Submit Application", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
