import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glimo/application/providers/auth_provider.dart';
import 'package:glimo/application/providers/auth_state.dart';
import 'package:glimo/domain/entities/user_entity.dart';

class UserProfile {
  final String name;
  final String? photoUrl;
  final String email;

  UserProfile({
    required this.name,
    this.photoUrl,
    required this.email,
  });

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    String? email,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    // Cek current auth state PERTAMA sebelum listen
    final currentAuthState = ref.read(authStateProvider);
    UserProfile initialProfile = UserProfile(
      name: 'Guest',
      photoUrl: null,
      email: 'guest@email.com',
    );

    // Jika sudah authenticated saat provider di-build, load profile langsung
    currentAuthState.maybeWhen(
      authenticated: (user) {
        initialProfile = UserProfile(
          name: user.fullName,
          photoUrl: null,
          email: user.email,
        );
      },
      orElse: () {},
    );

    // Subscribe to auth state changes untuk future updates
    ref.listen(authStateProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) {
          // Load profile dari auth user data saat authenticated
          _loadProfileFromAuth(user);
        },
        unauthenticated: () {
          // Reset ke default saat logout
          state = UserProfile(
            name: 'Guest',
            photoUrl: null,
            email: 'guest@email.com',
          );
        },
        orElse: () {},
      );
    });

    // Return initial profile (sudah bisa dari authenticated user atau Guest)
    return initialProfile;
  }

  void _loadProfileFromAuth(UserEntity user) {
    // Gunakan data dari Firebase (auth state)
    state = UserProfile(
      name: user.fullName,
      photoUrl: null,
      email: user.email,
    );

    // Simpan juga ke SharedPreferences untuk local cache
    _saveToLocalStorage(user.fullName, user.email, null);
  }

  Future<void> _saveToLocalStorage(String name, String email, String? photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    if (photoUrl != null) {
      await prefs.setString('user_photo_url', photoUrl);
    }
  }

  Future<void> updateName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
    state = state.copyWith(name: newName);
  }

  Future<void> updatePhoto(String photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo_url', photoUrl);
    state = state.copyWith(photoUrl: photoUrl);
  }

  Future<void> removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_photo_url');
    state = state.copyWith(photoUrl: null);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});