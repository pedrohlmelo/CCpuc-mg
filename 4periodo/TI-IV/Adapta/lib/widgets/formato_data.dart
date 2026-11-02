/// Textos de data e hora em português, sem depender de pacote de i18n.
library;

const _meses = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

/// "Hoje", "Ontem" ou "12 de set".
String rotuloDoDia(DateTime quando, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  final dia = DateTime(quando.year, quando.month, quando.day);
  final referencia = DateTime(hoje.year, hoje.month, hoje.day);
  final diferenca = referencia.difference(dia).inDays;
  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Ontem';
  return '${quando.day} de ${_meses[quando.month - 1]}';
}

/// "09:12".
String hora(DateTime quando) =>
    '${quando.hour.toString().padLeft(2, '0')}:'
    '${quando.minute.toString().padLeft(2, '0')}';

/// "Hoje às 09:12".
String diaEHora(DateTime quando, {DateTime? agora}) =>
    '${rotuloDoDia(quando, agora: agora)} às ${hora(quando)}';
