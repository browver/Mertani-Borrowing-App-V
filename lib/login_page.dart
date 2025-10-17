// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:User_App/homepage.dart';
// import 'package:flutter_application_2/menu_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_app/firebase_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// Hashed Password (optional)
String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}
//---------------------------

Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1));

    String inputUsername = _usernameController.text.trim();
    String inputPassword = _passwordController.text;

    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('username', isEqualTo: inputUsername)
      .limit(1)
      .get();

      if(userQuery.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User tidak ditemukan'), backgroundColor: Colors.red),
        );
        return;
      }
    
      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data() as Map<String, dynamic>;
        String? storedPassword = userData['password'];
        String role = userData['role'];

        if(storedPassword == null || storedPassword.isEmpty) {
          throw Exception('Password belum di-set');
        }

        if (inputPassword == storedPassword) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('role', role);
          await prefs.setString('userId', userQuery.docs.first.id);
          await prefs.setString('username', userData['username']);
          await FirestoreServices().updateUnknownHistroryEntries();

          if(!mounted) return;
          setState(() {
            _isLoading = false;
          });

          _usernameController.clear();
          _passwordController.clear();

        if (role == 'user' || role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/homepage', (route) => false);
          return;
        } 
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pengguna tidak dikenali'), backgroundColor: Colors.red),
          );
        }
        return;
        }
      }

    // Login Gagal
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      // Tampilkan pesan error jika login gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username atau password salah'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi Kesalahan. Coba lagi'),
          backgroundColor: Colors.red,
          ));
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo[600]!,
              Colors.indigo,
              Colors.indigo[200]!, 
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Section 
                  Container(
                    margin: EdgeInsets.only(bottom: 24.0), 
                    child: Column(
                      children: [
                        // Logo Container 
                        Container(
                          width: 80, 
                          height: 80, 
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20, 
                                offset: Offset(0, 8), 
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.3),
                                blurRadius: 30, 
                                offset: Offset(0, 15), 
                                spreadRadius: -3, 
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'pinjam_barang_logo',
                            child: Padding(
                              padding: EdgeInsets.all(16.0), 
                              child:
                                Image.asset('assets/icons/warehouse.png',
                                fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.0), 
                        
                        // App Title 
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16), 
                          child: Column(
                            crossAxisAlignment : CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Mertani Warehouse',
                                textAlign : TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 8,
                                      color: Colors.black.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.0), 
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 6, 
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16), 
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Pinjam barang dengan Mudah',
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login Form Card 
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.0), 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 25, 
                          offset: Offset(0, 15), 
                          spreadRadius: -3, 
                        ),
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.15),
                          blurRadius: 50,
                          offset: Offset(0, 30), 
                          spreadRadius: -15,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Login Title 
                          Text(
                            'Masuk ke Akun',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 20.0), 

                          // Username Field 
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.0), 
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withValues(alpha: 0.08),
                                  blurRadius: 6, 
                                  offset: Offset(0, 3), 
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14, 
                                ),
                                prefixIcon: Container(
                                  padding: EdgeInsets.all(10), 
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.indigo,
                                    size: 20, 
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.indigo,
                                    width: 2.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2.0,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.0, 
                                  vertical: 14.0, 
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.w500,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Silakan masukkan username';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 18.0), 

                          // Password Field 
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.0), 
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withValues(alpha: 0.08),
                                  blurRadius: 6, 
                                  offset: Offset(0, 3), 
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14, 
                                ),
                                prefixIcon: Container(
                                  padding: EdgeInsets.all(10), 
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.indigo,
                                    size: 20, 
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: Colors.grey[600],
                                    size: 20, 
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.indigo,
                                    width: 2.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2.0,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.0, 
                                  vertical: 14.0, 
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.w500,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Silakan masukkan password';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 24.0), 

                          // Login Button 
                          Container(
                            height: 48.0, 
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.0), 
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigo[400]!,
                                  Colors.indigo[400]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withValues(alpha: 0.4),
                                  blurRadius: 12, 
                                  offset: Offset(0, 6), 
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0), 
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login_rounded,
                                          size: 18, 
                                        ),
                                        SizedBox(width: 6), 
                                        Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 16.0), 
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.0), 

                  // Footer 
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16), 
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 14, 
                            ),
                            SizedBox(width: 6), 
                            Text(
                              'Safe & Encrypted',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12, 
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8), 
                        Text(
                          '  © 2025 Mertani App',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}