import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/veiculo.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/manutencao_repository.dart';
import '../utils/tipo_manutencao_labels.dart';
import 'lembrete_service.dart';

class NotificacaoService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes',
      'Lembretes de manutenção',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> _fila = Future.value();

  static Future<void> inicializar() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Refaz todas as notificações a partir do estado atual dos lembretes.
  /// As chamadas rodam em fila: duas ao mesmo tempo intercalariam o
  /// cancelamento de uma com o agendamento da outra.
  static Future<void> sincronizar(String uid, List<Veiculo> veiculos) {
    return _fila = _fila.then(
      (_) => _sincronizar(uid, veiculos),
      onError: (_) => _sincronizar(uid, veiculos),
    );
  }

  static Future<void> _sincronizar(String uid, List<Veiculo> veiculos) async {
    await _plugin.cancelAllPendingNotifications();
    final prefs = await SharedPreferences.getInstance();
    final agora = DateTime.now();
    var id = 0;

    Future<void> agendar(DateTime quando, String titulo, String corpo) {
      return _plugin.zonedSchedule(
        id: id++,
        title: titulo,
        body: corpo,
        // O instante em UTC é o mesmo do horário local, então não é preciso
        // carregar a base de fusos nem descobrir o fuso do aparelho.
        scheduledDate: tz.TZDateTime.from(quando, tz.UTC),
        notificationDetails: _detalhes,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    for (final veiculo in veiculos) {
      final lembretes = await LembreteRepository().getAll(uid, veiculoId: veiculo.id);
      final manutencoes = await ManutencaoRepository().getAll(uid, veiculoId: veiculo.id);

      for (final lembrete in lembretes.where((l) => l.ativo)) {
        final referencia =
            LembreteService.manutencaoMaisRecente(manutencoes, lembrete.tipoManutencao);
        final meta = LembreteService.calcularProximaMeta(
          lembrete: lembrete,
          kmReferencia: referencia?.kmNaData ?? 0,
          dataReferencia: referencia?.dataRealizada ?? agora,
        );
        final titulo = '${lembrete.tipoManutencao.label} - ${veiculo.nome}';

        final metaData = meta.metaData;
        if (metaData != null) {
          final diaDaMeta = DateTime(metaData.year, metaData.month, metaData.day);
          final avisos = LembreteService.proximosAvisos(
            inicio: diaDaMeta.subtract(Duration(days: lembrete.antecedenciaDias)),
            repeticaoDias: lembrete.intervaloRepeticaoDias,
            agora: agora,
          );
          for (final aviso in avisos) {
            final corpo = aviso.isBefore(diaDaMeta)
                ? 'Vence em ${_formatarData(metaData)}.'
                : 'Manutenção vencida desde ${_formatarData(metaData)}.';
            await agendar(aviso, titulo, corpo);
          }
        }

        final metaKm = meta.metaKm;
        if (metaKm == null) continue;
        final statusKm = LembreteService.calcularStatus(
          lembrete: lembrete,
          meta: MetaLembrete(metaKm: metaKm),
          kmAtual: veiculo.kmAtual,
          hoje: agora,
        );
        if (statusKm == StatusLembrete.emDia) continue;

        final corpo = statusKm == StatusLembrete.vencido
            ? 'Manutenção vencida: a meta de $metaKm km foi atingida.'
            : 'Faltam ${metaKm - veiculo.kmAtual} km para a meta de $metaKm km.';

        // Avisa na hora só quando o status por km muda; depois repete a cada
        // intervaloRepeticaoDias contados desse primeiro aviso.
        final chave = 'notificacao_km_${lembrete.id}';
        final chaveDesde = '${chave}_desde';
        final estado = '$metaKm:${statusKm.name}';
        if (prefs.getString(chave) != estado) {
          await _plugin.show(
            id: lembrete.id.hashCode & 0x7fffffff,
            title: titulo,
            body: corpo,
            notificationDetails: _detalhes,
          );
          await prefs.setString(chave, estado);
          await prefs.setString(chaveDesde, agora.toIso8601String());
        }
        final desde = DateTime.parse(prefs.getString(chaveDesde)!);
        final repeticoes = LembreteService.proximosAvisos(
          inicio: desde.add(Duration(days: lembrete.intervaloRepeticaoDias)),
          repeticaoDias: lembrete.intervaloRepeticaoDias,
          agora: agora,
        );
        for (final aviso in repeticoes) {
          await agendar(aviso, titulo, corpo);
        }
      }
    }
  }

  static String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
