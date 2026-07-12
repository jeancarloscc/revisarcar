import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseFirestoreDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  throw ArgumentError('Tipo de data inválido: ${value.runtimeType}');
}
