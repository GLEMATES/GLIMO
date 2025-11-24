import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Gagal membuat akun');
      }

      await user.sendEmailVerification();

      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        fullName: fullName,
        email: email,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email sudah terdaftar');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email tidak valid');
      } else {
        throw Exception('Gagal mendaftar: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Gagal login');
      }

      if (!user.emailVerified) {
        await _firebaseAuth.signOut();
        throw Exception('EMAIL_NOT_VERIFIED');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('Data user tidak ditemukan');
      }

      return UserModel.fromJson(userDoc.data()!);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak terdaftar');
      } else if (e.code == 'wrong-password') {
        throw Exception('Password salah');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email tidak valid');
      } else if (e.code == 'user-disabled') {
        throw Exception('Akun dinonaktifkan');
      } else {
        throw Exception('Gagal login: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Login dibatalkan');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Gagal login dengan Google');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!);
      } else {
        final now = DateTime.now();
        final userModel = UserModel(
          uid: user.uid,
          fullName: user.displayName ?? 'User',
          email: user.email ?? '',
          createdAt: now,
          updatedAt: now,
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toJson());

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('Akun sudah terdaftar dengan metode login lain');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Kredensial Google tidak valid');
      } else {
        throw Exception('Gagal login dengan Google: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      throw Exception('Gagal mendapatkan user: $e');
    }
  }

  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return UserModel.fromJson(userDoc.data()!);
    });
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak terdaftar');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email tidak valid');
      } else {
        throw Exception('Gagal mengirim email reset: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('🔐 [FIREBASE] Starting changePassword...');
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        debugPrint('🔐 [FIREBASE] User is null');
        throw Exception('User tidak ditemukan');
      }

      debugPrint('🔐 [FIREBASE] Current user: ${user.email}');

      final email = user.email;
      if (email == null) {
        throw Exception('Email user tidak ditemukan');
      }

      debugPrint('🔐 [FIREBASE] Creating credential for re-authentication...');
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      debugPrint('🔐 [FIREBASE] Re-authenticating user...');
      await user.reauthenticateWithCredential(credential);
      debugPrint('🔐 [FIREBASE] Re-authentication successful');

      debugPrint('🔐 [FIREBASE] Updating password...');
      await user.updatePassword(newPassword);
      debugPrint('🔐 [FIREBASE] Password updated successfully');

      // Verify user is still logged in
      final currentUser = _firebaseAuth.currentUser;
      debugPrint('🔐 [FIREBASE] User after password change: ${currentUser?.email}');
    } on FirebaseAuthException catch (e) {
      debugPrint('🔐 [FIREBASE] FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'wrong-password') {
        throw Exception('Password lama salah');
      } else if (e.code == 'weak-password') {
        throw Exception('Password baru terlalu lemah');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Silakan login ulang untuk mengubah password');
      } else {
        throw Exception('Gagal mengubah password: ${e.message}');
      }
    } catch (e) {
      debugPrint('🔐 [FIREBASE] Error: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      await user.reload();
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser?.emailVerified == true) {
        throw Exception('Email sudah terverifikasi');
      }

      await currentUser!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception('Terlalu banyak permintaan. Coba lagi nanti.');
      } else {
        throw Exception('Gagal mengirim email verifikasi: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      await user.reload();
      return _firebaseAuth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentUserEmail() async {
    return _firebaseAuth.currentUser?.email;
  }
}