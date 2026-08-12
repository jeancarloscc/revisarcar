import '../models/abastecimento.dart';

extension TipoCombustivelLabel on TipoCombustivel {
  String get label {
    switch (this) {
      case TipoCombustivel.gasolina:
        return 'Gasolina';
      case TipoCombustivel.etanol:
        return 'Etanol';
      case TipoCombustivel.diesel:
        return 'Diesel';        
    }
  }
}
