class BookingCategory {
  final String key;     // manicure/pedicure/lashes/brows
  final String title;
  final String emoji;

  const BookingCategory(this.key, this.title, this.emoji);
}

const bookingCategories = <BookingCategory>[
  BookingCategory('manicure', 'Маникюр', '💅'),
  BookingCategory('pedicure', 'Педикюр', '🦶'),
  BookingCategory('lashes', 'Ресницы', '👁️'),
  BookingCategory('brows', 'Брови', '✨'),
];
