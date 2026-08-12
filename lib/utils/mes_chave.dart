const _mesesPt = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String chaveMes(DateTime data) => '${data.year}-${data.month.toString().padLeft(2, '0')}';

String chaveMesAtual() => chaveMes(DateTime.now());

String passoMes(String chave, int delta) {
  final partes = chave.split('-');
  final ano = int.parse(partes[0]);
  final mes = int.parse(partes[1]);
  final data = DateTime(ano, mes + delta, 1);
  return chaveMes(data);
}

String formatarChaveMes(String chave) {
  final partes = chave.split('-');
  final ano = int.parse(partes[0]);
  final mes = int.parse(partes[1]);
  return '${_mesesPt[mes - 1]} de $ano';
}
