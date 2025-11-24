// lib/services/AppUser_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reto_habitos/src/models/users.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> createOrUpdateAppUser(AppUser user) async {
    await _firestore
      .collection('users')
      .doc(user.id)
      .set(user.toJson(), SetOptions(merge: true));
  }

  Future<AppUser?> getAppUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromJson(doc.data()!..['id'] = doc.id);
    }
    return null;
  }

  Stream<AppUser?> getAppUserStream(String userId) {
    return _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromJson(doc.data()!..['id'] = doc.id) : null);
  }

  Future<void> updateLastLogin(String userId) async {
    await _firestore
      .collection('users')
      .doc(userId)
      .update({'lastLogin': FieldValue.serverTimestamp()});
  }

  // Referencia a la subcolección de hábitos del usuario
  CollectionReference getAppUserHabitsCollection(String userId) {
    return _firestore
      .collection('users')
      .doc(userId)
      .collection('habits');
  }
}