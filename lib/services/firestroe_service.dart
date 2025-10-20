import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get reference to user's spending collection
  CollectionReference<Map<String, dynamic>> _getSpendingsRef() {
    final user = _auth.currentUser;
    return _db.collection("users").doc(user!.uid).collection("spendings");
  }

  /// Add a new spending
  Future<void> addSpending({
    required double amount,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    await _getSpendingsRef().add({
      "amount": amount,
      "category": category,
      "note": note ?? "",
      "date": Timestamp.fromDate(date ?? DateTime.now()),
    });
  }

  Future<void> deleteSpending(String docId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spendings')
        .doc(docId)
        .delete();
  }

  Future<void> updateSpending(
    String docId,
    Map<String, dynamic> updatedData,
  ) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spendings')
        .doc(docId)
        .update(updatedData);
  }

  /// Get all spendings (ordered by date)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllSpendings() {
    return _getSpendingsRef().orderBy("date", descending: true).snapshots();
  }

  /// Get spendings by category
  Stream<QuerySnapshot<Map<String, dynamic>>> getSpendingsByCategory(
    String category,
  ) {
    return _getSpendingsRef()
        .where("category", isEqualTo: category)
        .orderBy("date", descending: true)
        .snapshots();
  }

  /// Get spendings greater than amount
  Stream<QuerySnapshot<Map<String, dynamic>>> getHighSpendings(
    double minAmount,
  ) {
    return _getSpendingsRef()
        .where("amount", isGreaterThan: minAmount)
        .orderBy("amount", descending: true)
        .snapshots();
  }

  /// Get last N spendings
  Stream<QuerySnapshot<Map<String, dynamic>>> getRecentSpendings(
    int limitCount,
  ) {
    return _getSpendingsRef()
        .orderBy("date", descending: true)
        .limit(limitCount)
        .snapshots();
  }

  /// Get spendings between two dates
  Stream<QuerySnapshot<Map<String, dynamic>>> getSpendingsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _getSpendingsRef()
        .where("date", isGreaterThanOrEqualTo: start)
        .where("date", isLessThanOrEqualTo: end)
        .orderBy("date", descending: true)
        .snapshots();
  }
}
