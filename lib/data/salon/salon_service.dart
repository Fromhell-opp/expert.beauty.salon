import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalonService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  SalonService({FirebaseFirestore? db, FirebaseAuth? auth})
      : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<String> createSalon({
    required String name,
    required String phone,
    required String city,
    required String address,
    required String slug, // телефон-слуг (цифры)
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('Нет авторизации. Войди или включи Anonymous Auth.');
    }

    // 1) проверка что slug свободен
    final slugRef = db.collection('slugs').doc(slug);
    final slugSnap = await slugRef.get();
    if (slugSnap.exists) {
      throw Exception('Этот телефон уже занят (slug=$slug).');
    }

    // 2) создаём салон autoId
    final salonRef = db.collection('salons').doc();
    final now = FieldValue.serverTimestamp();

    final batch = db.batch();

    batch.set(salonRef, {
      'name': name,
      'phone': phone,
      'city': city,
      'address': address,
      'ownerId': user.uid,
      'slug': slug,
      'createdAt': now,
    });

    // 3) создаём slugs/{slug} -> salonId
    batch.set(slugRef, {
      'salonId': salonRef.id,
      'createdAt': now,
    });

    // 4) обновляем users/{uid}
    final userRef = db.collection('users').doc(user.uid);
    batch.set(userRef, {
      'role': 'owner',
      'salonId': salonRef.id,
      'name': 'Пользователь',
      'updatedAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
    return salonRef.id;
  }
}
