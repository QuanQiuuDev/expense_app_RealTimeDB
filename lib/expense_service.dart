import 'package:firebase_database/firebase_database.dart';

class ExpenseService {
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref("expenses");

  //  thêm dữ liệu
  Future<void> addExpense(int amount, String note, String category) async {
    await dbRef.push().set({
      "amount": amount,
      "note": note,
      "category": category, 
      "time": DateTime.now().toString(),
    });
  }

  //  xóa dữ liệu
  Future<void> deleteExpense(String key) async {
    await dbRef.child(key).remove();
  }

  //  sửa dữ liệu
  Future<void> updateExpense(
      String key, int amount, String note, String category) async {
    await dbRef.child(key).update({
      "amount": amount,
      "note": note,
      "category": category,
      "time": DateTime.now().toString(),
    });
  }

  // realtime
  DatabaseReference getRef() {
    return dbRef;
  }
}