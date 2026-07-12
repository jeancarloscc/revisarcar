import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreRepository<T> {
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId});

  T fromMap(String id, Map<String, dynamic> data, {String? veiculoId});
  Map<String, dynamic> toMap(T item);

  Stream<List<T>> watchAll(String uid, {String? veiculoId}) {
    return collection(uid, veiculoId: veiculoId).snapshots().map(
          (snap) => snap.docs
              .map((d) => fromMap(d.id, d.data(), veiculoId: veiculoId))
              .toList(),
        );
  }

  Future<List<T>> getAll(String uid, {String? veiculoId}) async {
    final snap = await collection(uid, veiculoId: veiculoId).get();
    return snap.docs.map((d) => fromMap(d.id, d.data(), veiculoId: veiculoId)).toList();
  }

  Future<String> add(String uid, T item, {String? veiculoId}) async {
    final ref = await collection(uid, veiculoId: veiculoId).add(toMap(item));
    return ref.id;
  }

  Future<T?> get(String uid, String id, {String? veiculoId}) async {
    final snap = await collection(uid, veiculoId: veiculoId).doc(id).get();
    if (!snap.exists) return null;
    return fromMap(snap.id, snap.data()!, veiculoId: veiculoId);
  }

  Future<void> update(String uid, String id, T item, {String? veiculoId}) {
    return collection(uid, veiculoId: veiculoId).doc(id).update(toMap(item));
  }

  Future<void> delete(String uid, String id, {String? veiculoId}) {
    return collection(uid, veiculoId: veiculoId).doc(id).delete();
  }
}
