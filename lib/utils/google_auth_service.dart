import 'package:check_in/modules/login/view/login_screen.dart';
import 'package:check_in/modules/splash/view/splash_screen.dart';
import 'package:check_in/utils/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static GoogleSignInAccount? currentUser;

  static Future<void> initialize() async {
    await GoogleSignIn.instance.initialize();
  }

  /// Sign in with Google and connect to Firebase
  static Future<User?> signInWithGoogle() async {
    try {
      // 1. Sign in with Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();
      if (googleUser == null) return null;

      // 2. Get Google authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // 5. Update local state
      currentUser = googleUser;

      return userCredential.user;
    } catch (error) {
      print('Google Sign-In with Firebase Error: $error');
      return null;
    }
  }

  /// Sign out from both Google and Firebase
  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
    currentUser = null;
    Navigation.pushAndRemoveUntil(const LoginScreen());
  }
}
