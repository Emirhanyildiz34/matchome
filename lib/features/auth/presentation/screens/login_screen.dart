import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/turkish_cities.dart';
import '../../../../core/constants/university_data.dart';
import '../../../../core/widgets/glass_container.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Ortak
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Controller'lar
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Ekstra Kayıt Alanları
  bool _isStudent = true;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedUniversity;
  String? _selectedCampus;
  StreamSubscription<AuthState>? _authStateSub;

  @override
  void initState() {
    super.initState();

    _authStateSub =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
        // Router redirect onboarding/discover kararını burada verir.
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _submitMainAction() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final repo = ref.read(authRepositoryProvider);

    try {
      if (_isSignUp) {
        // KAYIT OL
        if (name.isEmpty || email.isEmpty || password.isEmpty) {
          throw Exception(
              'Lütfen zorunlu alanları doldurun (Ad, Email, Şifre).');
        }
        if (_selectedCity == null || _selectedDistrict == null) {
          throw Exception('Lütfen Şehir ve İlçe seçin.');
        }
        if (_isStudent &&
            (_selectedUniversity == null || _selectedCampus == null)) {
          throw Exception('Öğrenciler için Üniversite ve Kampüs zorunludur.');
        }

        await repo.signUpWithEmail(
          email: email,
          password: password,
          fullName: name,
          phone: phone,
          isStudent: _isStudent,
          city: _selectedCity,
          district: _selectedDistrict,
          university: _selectedUniversity ?? '',
          campus: _selectedCampus ?? '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt Başarılı! Hoş Geldiniz.')),
          );
          // Yeni kayıtlarda onboarding'e yönlendir
          context.go('/onboarding');
        }
      } else {
        // GİRİŞ YAP
        if (email.isEmpty) throw Exception('Lütfen e-posta adresinizi girin.');
        if (password.isEmpty) throw Exception('Lütfen şifrenizi girin.');

        await repo.signInWithEmail(email, password);
        if (mounted) {
          // Router redirect onboarding tamamlanmışsa discover'a yönlendirir
          context.go('/login');
        }
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') || msg.contains('rate_limit')) {
        _showError(
            'E-posta gönderim limiti aşıldı. Lütfen 1 saat bekleyip tekrar deneyin veya farklı bir e-posta adresi kullanın.');
      } else if (msg.contains('already registered') ||
          msg.contains('already been registered')) {
        _showError('Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.');
      } else if (msg.contains('invalid login')) {
        _showError('E-posta veya şifre hatalı.');
      } else if (msg.contains('email not confirmed')) {
        _showError(
            'E-posta adresiniz doğrulanmamış. Lütfen e-postanızı kontrol edin.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Failed to fetch') || msg.contains('ClientException')) {
        _showError(
            'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin veya birkaç dakika sonra tekrar deneyin.');
      } else if (msg.contains('rate_limit') || msg.contains('429')) {
        _showError(
            'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.');
      } else {
        _showError(msg.replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Supabase OAuth web'de yönlendirme yapar; redirect sonrası router otomatik yönetir.
    } catch (e) {
      _showError(
          'Google ile giriş yapılamadı: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          dropdownColor: const Color(0xFF3B1F68),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Arama dialogını açan tıklanabilir alan
  Widget _buildSearchTile({
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.search, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  /// Aranabilir liste dialogı
  Future<String?> _showUniversitySearchDialog(
    BuildContext ctx, {
    required List<String> items,
    required String title,
    required String hintText,
    String? currentValue,
  }) async {
    String query = '';
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          final filtered = query.isEmpty
              ? items
              : items
                  .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogCtx).size.height * 0.75,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.orangeAccent),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setS(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text('Sonuç bulunamadı',
                                  style: TextStyle(color: Colors.white54)),
                            ))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final isSel = item == currentValue;
                                return ListTile(
                                  dense: true,
                                  title: Text(item,
                                      style: TextStyle(
                                        color: isSel
                                            ? Colors.orangeAccent
                                            : Colors.white,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      )),
                                  trailing: isSel
                                      ? const Icon(Icons.check,
                                          color: Colors.orangeAccent, size: 18)
                                      : null,
                                  onTap: () =>
                                      Navigator.of(dialogCtx).pop(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan rengi ve gradientler
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302B63),
                  Color(0xFF24243E)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Gradient küreler (Blob)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.deepPurpleAccent, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orangeAccent.withValues(alpha: 0.6),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(32.0),
                  borderRadius: BorderRadius.circular(32),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.maps_home_work_rounded,
                            size: 60, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'MatchHome',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp
                              ? 'Hemen Yeni Kayıt Oluştur'
                              : 'Sana Uygun Evi Bulmak İçin Giriş Yap',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        // NORMAL GİRİŞ VEYA KAYIT BÖLÜMÜ
                        if (_isSignUp) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Ad Soyad',
                            icon: Icons.person,
                          ),
                        ],

                        _buildTextField(
                          controller: _emailController,
                          label: 'E-posta Adresi',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        if (_isSignUp)
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Telefon Numarası',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),

                        _buildTextField(
                          controller: _passwordController,
                          label: 'Şifre',
                          icon: Icons.lock,
                          isPassword: true,
                        ),

                        if (_isSignUp) ...[
                          const Divider(color: Colors.white30, height: 32),
                          // Öğrenci Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.school,
                                      color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text('Öğrenciyim',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 16)),
                                ],
                              ),
                              Switch(
                                value: _isStudent,
                                onChanged: (val) =>
                                    setState(() => _isStudent = val),
                                activeThumbColor: Colors.orangeAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_isStudent) ...[
                            _buildSearchTile(
                              value: _selectedUniversity,
                              hint: 'Üniversite Seçin',
                              icon: Icons.account_balance,
                              onTap: () async {
                                final result =
                                    await _showUniversitySearchDialog(
                                  context,
                                  items: UniversityData.universityNames,
                                  title: 'Üniversite Seç',
                                  hintText: 'Üniversite adı yazın...',
                                  currentValue: _selectedUniversity,
                                );
                                if (result != null) {
                                  setState(() {
                                    _selectedUniversity = result;
                                    _selectedCampus = null;
                                  });
                                }
                              },
                            ),
                            if (_selectedUniversity != null)
                              _buildSearchTile(
                                value: _selectedCampus,
                                hint: 'Kampüs Seçin',
                                icon: Icons.location_city,
                                onTap: () async {
                                  final result =
                                      await _showUniversitySearchDialog(
                                    context,
                                    items: UniversityData.getCampusNames(
                                        _selectedUniversity!),
                                    title: 'Kampüs Seç',
                                    hintText: 'Kampüs adı yazın...',
                                    currentValue: _selectedCampus,
                                  );
                                  if (result != null) {
                                    setState(() => _selectedCampus = result);
                                  }
                                },
                              ),
                          ],

                          // Şehir / İlçe Seçimi
                          _buildDropdown(
                            value: _selectedCity,
                            hint: 'Şehir Seçin',
                            icon: Icons.location_on,
                            items: TurkishCities.cities,
                            onChanged: (val) {
                              setState(() {
                                _selectedCity = val;
                                _selectedDistrict =
                                    null; // Şehir değiştiğinde ilçeyi sıfırla
                              });
                            },
                          ),

                          if (_selectedCity != null)
                            _buildDropdown(
                              value: _selectedDistrict,
                              hint: 'İlçe Seçin',
                              icon: Icons.map,
                              items:
                                  TurkishCities.districts[_selectedCity] ?? [],
                              onChanged: (val) =>
                                  setState(() => _selectedDistrict = val),
                            ),
                        ],

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitMainAction,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isSignUp ? 'Kayıt Ol' : 'Giriş Yap',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // ── Ayırıcı ──
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'veya',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Google Butonu ──
                        SizedBox(
                          width: double.infinity,
                          child: _isGoogleLoading
                              ? OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : SignInButton(
                                  Buttons.googleDark,
                                  text: 'Continue with Google',
                                  onPressed: _signInWithGoogle,
                                ),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () => setState(() {
                            _isSignUp = !_isSignUp;
                          }),
                          child: Text(
                            _isSignUp
                                ? 'Zaten hesabınız var mı? Giriş Yapın'
                                : 'Hesabınız yok mu? Kayıt Olun',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
