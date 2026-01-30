String phoneToSlug(String input) {
  // оставляем только цифры
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits;
}
