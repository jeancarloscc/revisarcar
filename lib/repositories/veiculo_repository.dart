import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/veiculo.dart';
import 'firestore_repository.dart';

class VeiculoRepository extends FirestoreRepository<Veiculo> {
  final FirebaseFirestore _firestore;

  VeiculoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    return _firestore.collection('users').doc(uid).collection('veiculos');
  }

  @override
  Veiculo fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      Veiculo.fromMap(id, data);

  @override
  Map<String, dynamic> toMap(Veiculo item) => item.toMap();

  static const _subcolecoes = [
    'manutencoes',
    'abastecimentos',
    'lembretes',
    'checklistItems',
  ];

  Future<void> remover(String uid, String veiculoId) async {
    final veiculoDoc = collection(uid).doc(veiculoId);

    for (final nome in _subcolecoes) {
      final snapshot = await veiculoDoc.collection(nome).get();
      for (var i = 0; i < snapshot.docs.length; i += 500) {
        final lote = _firestore.batch();
        for (final doc in snapshot.docs.skip(i).take(500)) {
          lote.delete(doc.reference);
        }
        await lote.commit();
      }
    }

    await veiculoDoc.delete();
  }
}
