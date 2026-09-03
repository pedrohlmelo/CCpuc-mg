import 'package:flutter/material.dart';

/// Tokens visuais do Adapta.
///
/// Marca: índigo (confiança, foco) com o camaleão Camu em teal → lima
/// (adaptação). As cores de saúde da memória (seção 4 da memória) são
/// semânticas e não mudam com o tema.
class AppCores {
  AppCores._();

  static const indigo = Color(0xFF4F46E5);
  static const indigoEscuro = Color(0xFF3730A3);
  static const violeta = Color(0xFF7C3AED);
  static const teal = Color(0xFF14B8A6);
  static const lima = Color(0xFFA3E635);

  static const fundoClaro = Color(0xFFF6F7FB);
  static const superficieClara = Color(0xFFFFFFFF);
  static const tintaClara = Color(0xFF111827);
  static const tintaSuaveClara = Color(0xFF6B7280);
  static const bordaClara = Color(0xFFE5E7EB);

  static const fundoEscuro = Color(0xFF0F1222);
  static const superficieEscura = Color(0xFF181C30);
  static const tintaEscura = Color(0xFFF3F4F6);
  static const tintaSuaveEscura = Color(0xFF9CA3AF);
  static const bordaEscura = Color(0xFF2A2F4A);

  static const gradienteMarca = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violeta],
  );

  static const gradienteCamu = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [teal, lima],
  );
}

/// Cores da saúde da memória: consolidado / em risco / crítico / não estudado.
class CoresMemoria {
  CoresMemoria._();
  static const consolidado = Color(0xFF22C55E);
  static const emRisco = Color(0xFFF59E0B);
  static const critico = Color(0xFFEF4444);
  static const naoEstudado = Color(0xFF9CA3AF);
}

/// Raios e espaçamentos padrão. Um lugar só para o "feeling" do app.
class AppMedidas {
  AppMedidas._();
  static const raioCartao = 20.0;
  static const raioBotao = 14.0;
  static const raioCampo = 14.0;
  static const raioChip = 999.0;
  static const margemTela = 20.0;
}

const String _fonte = 'PlusJakartaSans';

ThemeData temaAdapta() => _tema(Brightness.light);
ThemeData temaAdaptaEscuro() => _tema(Brightness.dark);

ThemeData _tema(Brightness brilho) {
  final claro = brilho == Brightness.light;
  final base = ColorScheme.fromSeed(
    seedColor: AppCores.indigo,
    brightness: brilho,
  );
  final scheme = base.copyWith(
    primary: claro ? AppCores.indigo : const Color(0xFF8B85FF),
    onPrimary: Colors.white,
    primaryContainer: claro ? const Color(0xFFE0E7FF) : const Color(0xFF2E2A6B),
    onPrimaryContainer: claro ? AppCores.indigoEscuro : const Color(0xFFE0E7FF),
    secondary: AppCores.teal,
    onSecondary: Colors.white,
    secondaryContainer: claro
        ? const Color(0xFFCCFBF1)
        : const Color(0xFF134E4A),
    onSecondaryContainer: claro
        ? const Color(0xFF115E59)
        : const Color(0xFFCCFBF1),
    tertiary: claro ? const Color(0xFF65A30D) : AppCores.lima,
    surface: claro ? AppCores.superficieClara : AppCores.superficieEscura,
    onSurface: claro ? AppCores.tintaClara : AppCores.tintaEscura,
    onSurfaceVariant: claro
        ? AppCores.tintaSuaveClara
        : AppCores.tintaSuaveEscura,
    outline: claro ? AppCores.bordaClara : AppCores.bordaEscura,
    outlineVariant: claro ? AppCores.bordaClara : AppCores.bordaEscura,
    error: CoresMemoria.critico,
    surfaceContainerLowest: claro ? Colors.white : const Color(0xFF12152A),
    surfaceContainerLow: claro ? AppCores.fundoClaro : AppCores.fundoEscuro,
    surfaceContainer: claro ? const Color(0xFFEEF0F7) : const Color(0xFF1F2440),
    surfaceContainerHigh: claro
        ? const Color(0xFFE6E9F2)
        : const Color(0xFF262B4A),
  );

  final texto = _tipografia(scheme.onSurface, scheme.onSurfaceVariant);

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: scheme,
    fontFamily: _fonte,
    textTheme: texto,
    scaffoldBackgroundColor: claro ? AppCores.fundoClaro : AppCores.fundoEscuro,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: texto.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioCartao),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: texto.titleSmall,
      subtitleTextStyle: texto.bodySmall,
      iconColor: scheme.onSurfaceVariant,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      labelStyle: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioCampo),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioCampo),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioCampo),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioCampo),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioCampo),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.raioBotao),
        ),
        textStyle: texto.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.raioBotao),
        ),
        textStyle: texto.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: texto.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.raioBotao),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primaryContainer,
      side: BorderSide.none,
      labelStyle: texto.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMedidas.raioChip),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: texto.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.onSurface,
      contentTextStyle: texto.bodyMedium?.copyWith(color: scheme.surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHigh,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHigh,
      thumbColor: scheme.primary,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(textStyle: texto.bodyMedium),
  );
}

TextTheme _tipografia(Color tinta, Color tintaSuave) {
  TextStyle s(
    double tamanho,
    FontWeight peso, {
    double altura = 1.3,
    double espaco = 0,
    Color? cor,
  }) => TextStyle(
    fontFamily: _fonte,
    fontSize: tamanho,
    fontWeight: peso,
    height: altura,
    letterSpacing: espaco,
    color: cor ?? tinta,
  );

  return TextTheme(
    displayLarge: s(44, FontWeight.w800, altura: 1.1, espaco: -1.2),
    displayMedium: s(36, FontWeight.w800, altura: 1.1, espaco: -1.0),
    displaySmall: s(30, FontWeight.w800, altura: 1.15, espaco: -0.8),
    headlineLarge: s(28, FontWeight.w700, altura: 1.2, espaco: -0.6),
    headlineMedium: s(24, FontWeight.w700, altura: 1.2, espaco: -0.4),
    headlineSmall: s(20, FontWeight.w700, altura: 1.25, espaco: -0.2),
    titleLarge: s(18, FontWeight.w700, altura: 1.3),
    titleMedium: s(16, FontWeight.w600, altura: 1.35),
    titleSmall: s(14, FontWeight.w600, altura: 1.35),
    bodyLarge: s(16, FontWeight.w500, altura: 1.5),
    bodyMedium: s(14, FontWeight.w500, altura: 1.5),
    bodySmall: s(12.5, FontWeight.w500, altura: 1.4, cor: tintaSuave),
    labelLarge: s(15, FontWeight.w700, altura: 1.2, espaco: 0.1),
    labelMedium: s(13, FontWeight.w600, altura: 1.2),
    labelSmall: s(
      11.5,
      FontWeight.w600,
      altura: 1.2,
      espaco: 0.4,
      cor: tintaSuave,
    ),
  );
}

/// Sombra suave com tom da marca, para cartões em destaque.
List<BoxShadow> sombraSuave(BuildContext context) {
  final escuro = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: (escuro ? Colors.black : AppCores.indigo).withValues(
        alpha: escuro ? 0.35 : 0.08,
      ),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
