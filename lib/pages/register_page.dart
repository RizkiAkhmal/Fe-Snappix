import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "⚠️ Semua field wajib diisi";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Pendaftaran berhasil! Silakan login.")),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage = response['message'] ?? "Pendaftaran gagal";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.red),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildCircleImage(double w, double h, String asset, Color bgColor) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSmallCircle(double size, String asset, Color bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        image: DecorationImage(
          image: AssetImage(asset),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Stack(
                children: [
                  // Bulatan merah besar
                  Positioned(
                    top: -height * 0.2,
                    left: -width * 0.3,
                    right: -width * 0.3,
                    child: ClipOval(
                      child: Container(
                        height: height * 0.43,
                        color: Colors.red,
                      ),
                    ),
                  ),

                  // Tiga foto besar
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width * 0.9,
                      height: height * 0.4,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: width * 0.10,
                            child: _buildCircleImage(
                                width * 0.27,
                                height * 0.38,
                                'assets/images/Person1.png',
                                Color(0xFF6E1FED)),
                          ),
                          Positioned(
                            top: height * 0.02,
                            left: width * 0.39,
                            child: _buildCircleImage(width * 0.25, height * 0.3,
                                'assets/images/Person2.png', Color(0xFFF4B840)),
                          ),
                          Positioned(
                            top: height * 0.05,
                            left: width * 0.66,
                            child: _buildCircleImage(
                                width * 0.18,
                                height * 0.22,
                                'assets/images/Person3.png',
                                Color(0xFFFF7E29)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lingkaran kecil kanan
                  Positioned(
                    top: height * 0.30,
                    right: width * 0.13,
                    child: _buildSmallCircle(width * 0.20,
                        'assets/images/Person4.png', Color(0xFFF60D3D9)),
                  ),

                  // Lingkaran kecil kiri
                  Positioned(
                    top: height * 0.40,
                    left: width * 0.15,
                    child: _buildSmallCircle(width * 0.20,
                        'assets/images/Person5.png', Color(0xFFFF0084)),
                  ),

                  // Konten utama register
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: height * 0.45),

                        // Logo Snappix
                        SizedBox(
                          width: width * 0.15,
                          height: width * 0.15,
                          child: Image.asset(
                            'assets/images/Snappix.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: height * 0.005),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Ciptakan kehidupan\nYang Anda sukai",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20, // dikurangi dari 22
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: height * 0.02),
                        TextField(
                          controller: _usernameController,
                          decoration: _inputDecoration("Username"),
                        ),
                        SizedBox(height: height * 0.015),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Alamat Email"),
                        ),
                        SizedBox(height: height * 0.015),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration("Password"),
                        ),
                        SizedBox(height: height * 0.015),
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        SizedBox(height: height * 0.015),
                        SizedBox(
                          width: double.infinity,
                          height: height * 0.055, // sedikit lebih kecil
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "Daftar",
                                    style: TextStyle(
                                      fontSize: 15, // sedikit lebih kecil
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: height * 0.015),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Sudah punya akun? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              child: Text(
                                "Masuk",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.03),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
