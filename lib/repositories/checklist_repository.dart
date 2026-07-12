import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist_item.dart';
import 'firestore_repository.dart';

class ChecklistRepository extends FirestoreRepository<ChecklistItem> {
  final FirebaseFirestore _firestore;

  ChecklistRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'ChecklistRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('checklistItems');
  }

  @override
  ChecklistItem fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      ChecklistItem.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(ChecklistItem item) => item.toMap();
}
