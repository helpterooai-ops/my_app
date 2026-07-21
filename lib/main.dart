import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirestoreTest(),
    );
  }
}

class FirestoreTest extends StatefulWidget {
  @override
  _FirestoreTestState createState() => _FirestoreTestState();
}

class _FirestoreTestState extends State<FirestoreTest> {
  String _status = "جاري الاختبار...";

  @override
  void initState() {
    super.initState();
    testFirestoreConnection();
  }

  Future<void> testFirestoreConnection() async {
    try {
      // كتابة مستند تجريبي
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection')
          .set({'message': 'تم الاتصال بنجاح', 'timestamp': FieldValue.serverTimestamp()});

      // قراءة المستند
      final doc = await FirebaseFirestore.instance.collection('test').doc('connection').get();
      if (doc.exists) {
        setState(() {
          _status = '✅ ${doc.data()?['message']}';
        });
      } else {
        setState(() {
          _status = '❌ المستند غير موجود';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ فشل الاتصال: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار Firestore')),
      body: Center(
        child: Text(
          _status,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}