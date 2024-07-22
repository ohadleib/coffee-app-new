import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/my_button.dart';
import '../services/email_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _verificationId;
  bool _isCodeSent = false;
  bool _isEmailSelected = false;

  void _verifyPhoneNumber() async {
    String phoneNumber = _phoneController.text.trim();

    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+972' + phoneNumber;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        _checkIfNewUser();
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isCodeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _sendVerificationEmail() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid email address.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String code = _generateVerificationCode();
    await sendVerificationEmail(email, code);
    setState(() {
      _verificationId = code;
      _isCodeSent = true;
    });
  }

  String _generateVerificationCode() {
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += (0 + (Random().nextInt(9))).toString();
    }
    return code;
  }

  void _signInWithSMSCode() async {
    if (_verificationId != null) {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      _checkIfNewUser();
    }
  }

  void _signInWithEmailCode() async {
    if (_verificationId == _codeController.text) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _verificationId!,
        );
        _checkIfNewUser();
      } catch (e) {
        print('Error signing in with email: ${e.toString()}');
        _registerNewUser(); // רישום משתמש חדש במקרה של שגיאה
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid code. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _checkIfNewUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot userDocs = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: _emailController.text.trim()).get();
      if (userDocs.docs.isEmpty) {
        _registerNewUser();
      } else {
        _navigateToHome();
      }
    }
  }

  void _registerNewUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      });
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          userEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("lib/images/latte.png", height: 100),
              const SizedBox(height: 24),
              Text(
                "היי, ברוכים הבאים",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              const Text("הזינו את מספר הטלפון או המייל על מנת להיכנס"),
              const SizedBox(height: 16),
              ToggleButtons(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('טלפון'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('מייל'),
                  ),
                ],
                isSelected: [_isEmailSelected == false, _isEmailSelected == true],
                onPressed: (int index) {
                  setState(() {
                    _isEmailSelected = index == 1;
                    _isCodeSent = false;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!_isEmailSelected) ...[
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'מספר טלפון',
                    prefixText: '+972 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.brown),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.brown),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'מייל',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.brown),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.brown),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
              const SizedBox(height: 16),
              if (!_isCodeSent) ...[
                MyButton(
                  text: _isEmailSelected ? "שלחו לי קוד אימות במייל" : "שלחו לי קוד אימות",
                  onTap: _isEmailSelected ? _sendVerificationEmail : _verifyPhoneNumber,
                ),
              ] else ...[
                Text(
                  _isEmailSelected ? "שלחנו לך קוד אימות למייל" : "שלחנו לך קוד אימות לטלפון",
                  style: TextStyle(color: Colors.brown),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEmailSelected ? _emailController.text : _phoneController.text,
                  style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'קוד אימות',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.brown),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.brown),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                MyButton(
                  text: "אישור",
                  onTap: _isEmailSelected ? _signInWithEmailCode : _signInWithSMSCode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
