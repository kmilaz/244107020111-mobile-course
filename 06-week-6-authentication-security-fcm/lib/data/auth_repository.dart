/// Hasil login: sepasang token.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Auth tiruan yang **siap diganti Firebase Auth**.
///
/// Titik penggantinya hanya method `login`: ganti isinya dengan
/// `FirebaseAuth.instance.signInWithEmailAndPassword(...)`, lalu ambil
/// `getIdToken()` sebagai access token dan refresh token dari SDK. Sisanya
/// (TokenStore, interceptor 401, guard route) tidak perlu berubah — itulah
/// gunanya repository pattern.
class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!email.contains('@') || password.length < 6) {
      throw Exception('Email atau kata sandi tidak valid');
    }

    // JWT tiruan. Di produksi token ini diterbitkan server dan WAJIB
    // diverifikasi di sisi server — jangan pernah memercayai isi token
    // yang di-decode sendiri oleh aplikasi.
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) throw Exception('Refresh token hilang');
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
