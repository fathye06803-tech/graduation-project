import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addGoal({
    required String title,
    required double amount,
  }) async {
    await _db.collection("goals").add({
      "title": title,
      "amount": amount,
      "createdAt": Timestamp.now(),
    });
  }
}