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
  bool _isPasswordVisible = false;

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

  // Validasi input sebelum register
  bool _validateInputs() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty) {
      _showAlert('Input Tidak Lengkap', 'Username tidak boleh kosong.');
      return false;
    }

    if (username.length < 3) {
      _showAlert('Username Terlalu Pendek', 'Username minimal 3 karakter.');
      return false;
    }

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

  Future<void> _handleRegister() async {
    // Validasi input terlebih dahulu
    if (!_validateInputs()) {
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
        // Tampilkan alert sukses
        _showAlert(
          'Akun Sudah Dibuat!', 
          'Pendaftaran berhasil! Silakan login dengan akun baru Anda.',
          isSuccess: true
        );

        // Tunggu sebentar untuk user melihat alert, kemudian navigate
        await Future.delayed(Duration(milliseconds: 1500));
        
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final errorMsg = response['message'] ?? "Pendaftaran gagal";
        setState(() {
          _errorMessage = errorMsg;
        });
        
        // Tampilkan alert error
        _showAlert('Pendaftaran Gagal', errorMsg);
      }
    } catch (e) {
      final errorMsg = "Terjadi kesalahan: $e";
      setState(() {
        _errorMessage = errorMsg;
      });
      
      // Tampilkan alert untuk error koneksi atau server
      _showAlert(
        'Kesalahan Koneksi', 
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba lagi.'
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
                size: 22,
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
                          onSubmitted: (_) => _handleRegister(),
                        ),
                        SizedBox(height: height * 0.015),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Alamat Email"),
                          onSubmitted: (_) => _handleRegister(),
                        ),
                        SizedBox(height: height * 0.015),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration("Password", isPassword: true),
                          onSubmitted: (_) => _handleRegister(),
                        ),
                        SizedBox(height: height * 0.015),
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
                          height: height * 0.055, // sedikit lebih kecil
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: _isLoading ? 0 : 2,
                            ),
                            onPressed: _isLoading ? null : _handleRegister,
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
                                    "Daftar",
                                    style: TextStyle(
                                      fontSize: 15, // sedikit lebih kecil
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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