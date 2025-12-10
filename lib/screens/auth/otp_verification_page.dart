import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../database.dart';
import '../../services/otp_service.dart';
import '../../routes/app_routes.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final OtpService _otpService = OtpService();
  final DatabaseService _dbService = DatabaseService();

  bool isLoading = false;
  bool isResending = false;
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void showNotification(String message, {Color color = Colors.green}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  String _getOtpValue() {
    return _controllers.map((c) => c.text).join();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (_getOtpValue().length == 6) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _getOtpValue();
    if (otp.length != 6) {
      showNotification('Please enter the complete 6-digit OTP', color: Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _otpService.verifyOTP(widget.email, otp);

      if (result['success'] == true) {
        // OTP verified - now send Firebase password reset email
        final resetResult = await _dbService.sendPasswordResetEmail(widget.email);
        showNotification(
          'OTP verified! $resetResult',
          color: Colors.green,
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        showNotification(result['message'], color: Colors.red);
        _clearOtp();
      }
    } catch (e) {
      showNotification('Error: ${e.toString()}', color: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    if (_remainingSeconds > 0) return;

    setState(() => isResending = true);

    try {
      final result = await _otpService.sendOTP(widget.email);

      if (result['success'] == true) {
        showNotification('New OTP sent to ${widget.email}', color: Colors.green);
        _startTimer();
      } else {
        showNotification(result['message'], color: Colors.red);
      }
    } catch (e) {
      showNotification('Failed to resend OTP', color: Colors.red);
    } finally {
      setState(() => isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A85B6), Color(0xFFBAC8E0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black87, size: 26),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            'DOBBIE',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(2, 3),
                                )
                              ],
                            ),
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
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter the 6-digit code sent to\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // OTP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 48,
                                height: 56,
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.indigo.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) => _onOtpChanged(index, value),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 30),
                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _verifyOTP,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                backgroundColor: Colors.indigo.shade700,
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Verify OTP',
                                      style: TextStyle(color: Colors.white, fontSize: 18),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Resend OTP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive the code? ",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              if (_remainingSeconds > 0)
                                Text(
                                  'Resend in ${_remainingSeconds}s',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: isResending ? null : _resendOTP,
                                  child: Text(
                                    isResending ? 'Sending...' : 'Resend',
                                    style: TextStyle(
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
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
