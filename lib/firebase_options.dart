import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyC0PIRfuwLZnN_no9tzkKcTOCcpUDK_qeo',
  appId: '1:628103566446:android:23f0814c770337a446827f',
  projectId: 'coffe-app-very-new',
  messagingSenderId: '628103566446',
  storageBucket: 'coffe-app-very-new.appspot.com',
  );
}