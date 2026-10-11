String? requiredText(String? value, [String label = 'Поле']) {
  if (value == null || value.trim().isEmpty) return '$label обязательно';
  return null;
}

String? textLength(String? value,
    {required String label, int min = 2, int max = 120}) {
  final r = requiredText(value, label);
  if (r != null) return r;
  final n = value!.trim().length;
  if (n < min) return '$label: минимум $min символа';
  if (n > max) return '$label: максимум $max символов';
  return null;
}

String? emailValidator(String? value) {
  final r = requiredText(value, 'Email');
  if (r != null) return r;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
    return 'Некорректный формат email';
  }
  return null;
}

String? positiveInt(String? value, {required String label}) {
  final r = requiredText(value, label);
  if (r != null) return r;
  final n = int.tryParse(value!.trim());
  if (n == null || n <= 0) {
    return '$label должно быть положительным целым числом';
  }
  return null;
}

String? nonNegativeInt(String? value, {required String label}) {
  final r = requiredText(value, label);
  if (r != null) return r;
  final n = int.tryParse(value!.trim());
  if (n == null || n < 0) {
    return '$label должно быть неотрицательным целым числом';
  }
  return null;
}

String? positiveDouble(String? value, {required String label}) {
  final r = requiredText(value, label);
  if (r != null) return r;
  final n = double.tryParse(value!.replaceAll(',', '.').trim());
  if (n == null || n <= 0) return '$label должно быть положительным числом';
  return null;
}

String? phoneValidator(String? value) {
  final r = requiredText(value, 'Телефон');
  if (r != null) return r;
  if (!RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value!.trim())) {
    return 'Некорректный телефон';
  }
  return null;
}

String? selectionRequired(List<int>? value, {required String label}) =>
    value == null || value.isEmpty
        ? '$label: выберите хотя бы одно значение'
        : null;
