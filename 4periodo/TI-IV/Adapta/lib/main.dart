import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'dados/estado_app.dart';
import 'dados/firebase.dart';
import 'dados/preferencias.dart';
import 'tema/tema_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tema = await carregarTemaSalvo();
  final idMateria = await const Preferencias().lerIdMateria();
  final lingua = await const Preferencias().lerLinguaEstrangeira();
  final comFirebase = await iniciarFirebase();
  runApp(
    ProviderScope(
      overrides: [
        temaInicialProvider.overrideWithValue(tema),
        idMateriaInicialProvider.overrideWithValue(idMateria),
        linguaInicialProvider.overrideWithValue(lingua),
        if (comFirebase) ...[
          firebaseAuthProvider.overrideWithValue(FirebaseAuth.instance),
          firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
        ],
      ],
      child: const AdaptaApp(),
    ),
  );
}
