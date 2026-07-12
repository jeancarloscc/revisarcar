import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lembrete_manutencao.dart';
import 'firestore_repository.dart';

class LembreteRepository extends FirestoreRepository<LembreteManutencao> {
  final FirebaseFirestore _firestore;

  LembreteRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'LembreteRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('lembretes');
  }

  @override
  LembreteManutencao fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      LembreteManutencao.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(LembreteManutencao item) => item.toMap();
}
