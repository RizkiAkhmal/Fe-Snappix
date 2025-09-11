import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isPasswordVisible = false;
  String? _errorMessage;

  // Method untuk menampilkan alert dialog
  void _showAlert(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }


  // Validasi input sebelum login
  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showAlert('Input Tidak Lengkap', 'Alamat email tidak boleh kosong.');
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showAlert('Format Email Salah', 'Mohon masukkan alamat email yang valid.');
      return false;
    }

    if (password.isEmpty) {
      _showAlert('Input Tidak Lengkap', 'Password tidak boleh kosong.');
      return false;
    }

    if (password.length < 6) {
      _showAlert('Password Terlalu Pendek', 'Password minimal 6 karakter.');
      return false;
    }

    return true;
  }

  Future<void> _handleLogin() async {
    // Validasi input terlebih dahulu
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Debug: Print response untuk melihat struktur
      print('Login response: $result');

      if (result["success"] == true) {
        // Response structure: {success: true, user: {...}, token: "..."}
        final token = result["token"];
        final user = result["user"];
        
        if (token != null && user != null) {
          final name = user["name"] ?? "User";
          final userId = user["id"]?.toString() ?? "";
          final username = user["username"] ?? "";
          final avatar = user["avatar"] ?? "";

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", token);
          await prefs.setString("name", name);
          await prefs.setString("user_id", userId);
          await prefs.setString("username", username);
          await prefs.setString("avatar", avatar);

          // Tampilkan alert sukses
          _showAlert(
            'Login Berhasil!', 
            'Selamat datang, $name!',
            isSuccess: true
          );

          // Tunggu sebentar untuk user melihat alert, kemudian navigate
          await Future.delayed(Duration(milliseconds: 1500));
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(token: token)),
          );
        } else {
          // Token atau user tidak ada
          final errorMsg = "Response server tidak lengkap - token atau user tidak ditemukan";
          setState(() {
            _errorMessage = errorMsg;
          });
          _showAlert('Login Gagal', errorMsg);
        }

      } else {
        // Login gagal
        final errorMsg = result["message"] ?? "Email atau password salah";
        setState(() {
          _errorMessage = errorMsg;
        });
        
        // Tampilkan alert error
        _showAlert('Login Gagal', errorMsg);
      }
    } catch (e) {
  print('Login error: $e');
  String errorMsg;
  
  if (e.toString().contains('NoSuchMethodError')) {
    errorMsg = "Format response server tidak sesuai";
  } else if (e.toString().contains('SocketException')) {
    errorMsg = "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
  } else if (e.toString().contains('FormatException')) {
    errorMsg = "Response server tidak valid";
  } else {
    // Hilangkan prefix "Exception: " kalau ada
    errorMsg = e.toString().replaceFirst('Exception: ', '');
  }
  
  setState(() {
    _errorMessage = errorMsg;
  });
      
      // Tampilkan alert untuk error
      _showAlert(
        'Kesalahan Login', 
        errorMsg
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label, {bool isPassword = false}) {
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
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            )
          : null,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                            style: GoogleFonts.inter(
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
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        SizedBox(height: height * 0.03),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration("Password", isPassword: true),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        SizedBox(height: height * 0.025),
                        if (_errorMessage != null)
                          Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                              elevation: _isLoading ? 0 : 2,
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Masuk",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: height * 0.025),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Belum punya akun? ",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                "Daftar!",
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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