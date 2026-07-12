import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/manutencao.dart';
import 'firestore_repository.dart';

class ManutencaoRepository extends FirestoreRepository<Manutencao> {
  final FirebaseFirestore _firestore;

  ManutencaoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'ManutencaoRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('manutencoes');
  }

  @override
  Manutencao fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      Manutencao.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(Manutencao item) => item.toMap();
}
