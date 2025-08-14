import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../main_page.dart'; // Pastikan MainPage sudah dibuat

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result["success"] == true) {
        final token = result["token"];
        final name = result["user"]["name"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("name", name);

        Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => MainPage(token: token)),
);

      } else {
        setState(() {
          _errorMessage = result["message"] ?? "Email atau password salah";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: ${e.toString()}";
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
                  // Bulatan merah besar di atas
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

                  // Grup tiga foto besar
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

                  // Lingkaran kecil kanan bawah
                  Positioned(
                    top: height * 0.30,
                    right: width * 0.13,
                    child: _buildSmallCircle(width * 0.20,
                        'assets/images/Person4.png', Color(0xFFF60D3D9)),
                  ),

                  // Lingkaran kecil kiri bawah
                  Positioned(
                    top: height * 0.40,
                    left: width * 0.15,
                    child: _buildSmallCircle(width * 0.20,
                        'assets/images/Person5.png', Color(0xFFFF0084)),
                  ),

                  // Konten utama login
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: height * 0.45),

                        // Ganti Icon dengan Image.asset
                        SizedBox(
                          width: width * 0.15, // lebar icon sebelumnya
                          height: width *
                              0.15, // tinggi icon sebelumnya, supaya kotak
                          child: Image.asset(
                            'assets/images/Snappix.png', // ganti dengan path image kamu
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: height * 0.01),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Ciptakan kehidupan\nyang Anda sukai",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: height * 0.03),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Alamat Email"),
                        ),
                        SizedBox(height: height * 0.03),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration("Password"),
                        ),
                        SizedBox(height: height * 0.025),
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        SizedBox(height: height * 0.015),
                        SizedBox(
                          width: double.infinity,
                          height: height * 0.06,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "Masuk",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: height * 0.025),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Belum punya akun? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                "Daftar!",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
