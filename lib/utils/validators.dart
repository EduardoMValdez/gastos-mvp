class Validators {
  static final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'El correo es obligatorio';
    if (s.length > 254 || !_emailRe.hasMatch(s)) return 'Correo no válido';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Usa letras y números';
    }
    return null;
  }

  static double? parseAmount(String? v) => double.tryParse((v ?? '').trim());

  static String? amount(String? v) {
    final n = parseAmount(v);
    if (n == null) return 'Ingresa un monto válido';
    if (n <= 0) return 'El monto debe ser mayor a 0';
    if (n > 1000000) return 'Monto demasiado alto';
    return null;
  }

  static String? note(String? v) =>
      (v != null && v.trim().length > 120) ? 'Máximo 120 caracteres' : null;
}