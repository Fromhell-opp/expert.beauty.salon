import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);
    const card = Colors.white;
    const primary = Color(0xFFEC5B7E);

    final services = <_Service>[
      _Service(
        title: 'Маникюр',
        subtitle: 'от 1000 сом',
        icon: Icons.back_hand_rounded,
        color: const Color(0xFFFFE2E8),
      ),
      _Service(
        title: 'Педикюр',
        subtitle: 'от 1200 сом',
        icon: Icons.spa_rounded,
        color: const Color(0xFFFFF1D6),
      ),
      _Service(
        title: 'Ресницы',
        subtitle: 'от 1500 сом',
        icon: Icons.remove_red_eye_rounded,
        color: const Color(0xFFE7F0FF),
      ),
      _Service(
        title: 'Брови',
        subtitle: 'от 800 сом',
        icon: Icons.face_retouching_natural_rounded,
        color: const Color(0xFFE9FAF1),
      ),
    ];

    // 3 мастера по ресницам + 3 по ногтям (имена выдуманные)
    final masters = <_Master>[
      _Master(name: 'Алина', role: 'Мастер ресниц', rating: 4.9, category: 'lashes'),
      _Master(name: 'Саида', role: 'Мастер ресниц', rating: 4.8, category: 'lashes'),
      _Master(name: 'Камила', role: 'Мастер ресниц', rating: 4.7, category: 'lashes'),
      _Master(name: 'Гульзада', role: 'Nail мастер', rating: 4.9, category: 'nails'),
      _Master(name: 'Эльнура', role: 'Nail мастер', rating: 4.8, category: 'nails'),
      _Master(name: 'Мира', role: 'Nail мастер', rating: 4.7, category: 'nails'),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _TopBar(
                  salonName: 'EXPERT Beauty Salon',
                  onBellTap: () {},
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchField(
                  hint: 'Поиск услуг или мастера',
                  onChanged: (v) {},
                ),
              ),
            ),

            // Promo banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 10),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Запишись онлайн',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Выбери услугу и мастера — займёт 30 секунд',
                                style: TextStyle(color: Colors.black54, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Services
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Наши услуги',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Все'),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final s = services[index];
                    return _ServiceCard(
                      title: s.title,
                      subtitle: s.subtitle,
                      icon: s.icon,
                      bubbleColor: s.color,
                      onTap: () {
                        // TODO: здесь можно вести на экран выбора мастера по категории/услуге
                        // Navigator.pushNamed(context, '/select_master');
                      },
                    );
                  },
                  childCount: services.length,
                ),
              ),
            ),

            // Masters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Популярные мастера',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Все'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 168,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: masters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final m = masters[i];
                    return _MasterCard(
                      name: m.name,
                      role: m.role,
                      rating: m.rating,
                      onTap: () {
                        // TODO: вести на выбор даты/времени для конкретного мастера
                      },
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String salonName;
  final VoidCallback onBellTap;

  const _TopBar({
    required this.salonName,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Привет 👋', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                salonName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onBellTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bubbleColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bubbleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC5B7E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 10),
              color: Color(0x14000000),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: primary),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  final String name;
  final String role;
  final double rating;
  final VoidCallback onTap;

  const _MasterCard({
    required this.name,
    required this.role,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC5B7E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 10),
              color: Color(0x14000000),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "аватар" без картинок
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(role, style: const TextStyle(color: Colors.black54)),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: primary, size: 18),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE2E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text('Запись', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Service {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Service({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _Master {
  final String name;
  final String role;
  final double rating;
  final String category;
  const _Master({
    required this.name,
    required this.role,
    required this.rating,
    required this.category,
  });
}
