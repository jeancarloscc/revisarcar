import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/intervalo_manutencao.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/providers/manutencao_provider.dart';
import 'package:revisacar/repositories/lembrete_repository.dart';
import 'package:revisacar/repositories/manutencao_repository.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';

void main() {
  test('escutarVeiculo carrega as manutenções daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: VeiculoRepository(firestore),
      lembreteRepository: LembreteRepository(firestore),
      uid: 'uid1',
    );

    provider.escutarVeiculo('v1');
    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.manutencoes, hasLength(1));
  });

  test('adicionar atualiza Veiculo.kmAtual quando o km da manutenção é maior', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: veiculoRepository,
      lembreteRepository: LembreteRepository(firestore),
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 41000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final veiculoAtualizado = await veiculoRepository.get('uid1', veiculoId);
    expect(veiculoAtualizado?.kmAtual, 41000);
  });

  test('adicionar não reduz Veiculo.kmAtual quando o km da manutenção é menor (registro atrasado)',
      () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: veiculoRepository,
      lembreteRepository: LembreteRepository(firestore),
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2025, 12, 1),
      kmNaData: 42000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final veiculoAtualizado = await veiculoRepository.get('uid1', veiculoId);
    expect(veiculoAtualizado?.kmAtual, 45000);
  });

  test('adicionar cria lembrete automático quando não existe nenhum daquele tipo', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, hasLength(1));
    final lembrete = lembretes.first;
    expect(lembrete.tipoManutencao, TipoManutencao.trocaOleo);
    expect(lembrete.intervaloKm, 10000);
    expect(lembrete.intervaloDias, 360);
    expect(lembrete.antecedenciaKm, 500);
    expect(lembrete.antecedenciaDias, 15);
    expect(lembrete.intervaloRepeticaoDias, 3);
    expect(lembrete.ativo, isTrue);
  });

  test('adicionar não cria um segundo lembrete quando já existe um daquele tipo', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final lembreteRepository = LembreteRepository(firestore);
    await lembreteRepository.add(
      'uid1',
      LembreteManutencao(
        id: '',
        veiculoId: veiculoId,
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 12000,
        antecedenciaKm: 0,
        antecedenciaDias: 0,
        intervaloRepeticaoDias: 3,
        ativo: false,
      ),
      veiculoId: veiculoId,
    );
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, hasLength(1));
    expect(lembretes.first.intervaloKm, 12000);
  });

  test('adicionar não cria lembrete para o tipo Outro', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.outro,
      descricaoOutro: 'Troca de parabrisa',
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, isEmpty);
  });

  test('adicionar não cria lembrete quando o intervalo efetivo do veículo está vazio', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
        intervalosPersonalizados: {
          TipoManutencao.trocaOleo: IntervaloManutencao(),
        },
      ),
    );
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, isEmpty);
  });

  test('atualizar não cria lembrete', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final manutencaoRepository = ManutencaoRepository(firestore);
    final manutencaoId = await manutencaoRepository.add(
      'uid1',
      Manutencao(
        id: '',
        veiculoId: veiculoId,
        tipo: TipoManutencao.trocaOleo,
        dataRealizada: DateTime(2026, 1, 1),
        kmNaData: 40500,
        custo: 200.0,
        oficina: 'Oficina',
        observacoes: '',
      ),
      veiculoId: veiculoId,
    );
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: manutencaoRepository,
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.atualizar(Manutencao(
      id: manutencaoId,
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 41000,
      custo: 250.0,
      oficina: 'Oficina 2',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, isEmpty);
  });
}
