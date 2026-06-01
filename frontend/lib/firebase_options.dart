import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // This is a dummy file. 
    // You MUST run `flutterfire configure` to generate the real configuration!
    return const FirebaseOptions(
      apiKey: 'AIzaSyCEbVEHB1aaODGNItpSrBfCvenMR3jVxYA',
      appId: '1:490417892844:android:3151cc1d325c76d16224c9',
      messagingSenderId: '490417892844',
      projectId: 'gridpooled',
      storageBucket: 'gridpooled.firebasestorage.app',
    );
  }
}
