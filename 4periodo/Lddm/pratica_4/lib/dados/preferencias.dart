import 'package:shared_preferences/shared_preferences.dart';

Future<void> salvarTema(bool escuro) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tema_escuro', escuro);
}

Future<bool> lerTema() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tema_escuro') ?? false;
}
