import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nulos quando o Firebase não subiu: o app segue só com o SQLite.
final firebaseAuthProvider = Provider<FirebaseAuth?>((_) => null);
final firestoreProvider = Provider<FirebaseFirestore?>((_) => null);

/// Sobe o Firebase com a configuração nativa do aparelho
/// (`google-services.json` / `GoogleService-Info.plist`). Devolve `false` se
/// ela não existir ou falhar: nesse caso o app abre usando só o SQLite.
Future<bool> iniciarFirebase() async {
  try {
    await Firebase.initializeApp();
    // O SQLite já é o armazenamento offline: sem cache duplicado do Firestore.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    return true;
  } catch (_) {
    return false;
  }
}
