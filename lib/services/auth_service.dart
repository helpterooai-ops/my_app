import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // Stream لمتابعة حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========== تسجيلByEmail ==========
  
  // إنشاء حساب جديد
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // حفظ بيانات المستخدم في Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phoneNumber': '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print('Error in signUpWithEmail: $e');
      rethrow;
    }
  }

  // تسجيل دخولByEmail
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // تحديث آخر ظهور
        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print('Error in signInWithEmail: $e');
      rethrow;
    }
  }

  // ========== تسجيل بـ Google ==========
  
  Future<User?> signInWithGoogle() async {
    try {
      // بدء عملية تسجيل الدخول بـ Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // المستخدم ألغى العملية
        return null;
      }

      // الحصول على بيانات المصادقة
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // إنشاء credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول في Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // التحقق إذا كان المستخدم موجود مسبقاً
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // مستخدم جديد، حفظ بياناته
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phoneNumber': '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
          });
        } else {
          // مستخدم موجود، تحديث آخر ظهور
          await _firestore.collection('users').doc(user.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      rethrow;
    }
  }

  // ========== تسجيل الخروج ==========
  
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ========== إعادة تعيين كلمة المرور ==========
  
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}