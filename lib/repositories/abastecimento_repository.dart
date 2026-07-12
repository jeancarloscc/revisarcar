import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/abastecimento.dart';
import 'firestore_repository.dart';

class AbastecimentoRepository extends FirestoreRepository<Abastecimento> {
  final FirebaseFirestore _firestore;

  AbastecimentoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'AbastecimentoRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('abastecimentos');
  }

  @override
  Abastecimento fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      Abastecimento.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(Abastecimento item) => item.toMap();
}
