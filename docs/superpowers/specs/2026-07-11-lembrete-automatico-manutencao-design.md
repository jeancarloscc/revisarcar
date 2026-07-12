# Lembrete automático ao registrar manutenção — Design

Data: 2026-07-11

## Contexto e objetivo

Hoje um `LembreteManutencao` é uma regra recorrente (intervalo em km e/ou dias) que o usuário precisa cadastrar manualmente na aba Lembretes, para cada tipo de manutenção que queira acompanhar. O `LembreteService` já recalcula a próxima meta (km/data) reativamente, com base na manutenção mais recente daquele tipo — mas só se a regra já existir.

Objetivo desta fase: quando o usuário registra uma manutenção de um tipo que ainda não tem regra de lembrete configurada naquele veículo, o app cria essa regra automaticamente, usando um intervalo padrão (por tipo, personalizável por veículo). Assim o usuário não precisa configurar manualmente um lembrete para começar a receber alertas.

Referência: `docs/superpowers/specs/2026-07-05-app-manutencao-veicular-design.md` (design geral do app) e `docs/superpowers/specs/2026-07-10-fase-b-detalhe-veiculo-design.md` (telas de Manutenções/Lembretes já implementadas).

## Escopo

**Dentro do escopo:**
- Tabela de intervalos padrão por `TipoManutencao` (baseada no manual do proprietário Hyundai HB20, com ajustes de mercado para itens não cobertos pelo manual), embutida no código.
- Campo `intervalosPersonalizados` em `Veiculo`, permitindo sobrescrever o padrão por veículo (incluindo "desligar" a criação automática para um tipo específico, deixando km e dias em branco).
- Seção "Intervalos de manutenção" na tela `VeiculoFormScreen`, com um campo de km e um de meses por tipo (exceto "Outro"), pré-preenchidos com o valor efetivo atual.
- Criação automática de `LembreteManutencao` em `ManutencaoProvider.adicionar()` quando: a manutenção é uma manutenção **nova** (não edição), o tipo não é "Outro", ainda não existe nenhum lembrete daquele tipo naquele veículo, e o intervalo efetivo (km e/ou dias) não está totalmente vazio.
- Método de leitura pontual (`getAll`) no repositório genérico, para checar lembretes existentes sem precisar de uma stream ativa.

**Fora do escopo (não faz parte desta fase):**
- Editar `antecedenciaKm`/`antecedenciaDias`/`intervaloRepeticaoDias` na tela de configuração do veículo — o lembrete criado automaticamente usa valores fixos (500km / 15 dias / repetir a cada 3 dias), editáveis depois manualmente na aba Lembretes.
- Criar/atualizar lembrete ao **editar** uma manutenção existente — só ao adicionar uma nova.
- Recalcular ou recriar lembretes já existentes quando o usuário muda os intervalos padrão do veículo — a mudança só vale para tipos sem lembrete ainda.
- Tipo "Outro": nunca entra na tabela de padrões, nunca aparece na tela de configuração, nunca gera lembrete automático (cada registro tem uma descrição livre diferente, sem um intervalo comum).
- Qualquer mudança em agendamento de notificações locais (já fora do escopo do app hoje, conforme spec geral).

## Tabela de intervalos padrão

Baseada no manual do proprietário HB20 (plano de manutenção normal — "o que ocorrer primeiro"). Itens sem cadência definida no manual usam prática comum de mercado (marcados como "mercado" abaixo).

| TipoManutencao | km padrão | meses padrão | Fonte |
|---|---|---|---|
| `revisao` | 10.000 | 12 | Manual (ciclo base da tabela) |
| `trocaOleo` | 10.000 | 12 | Manual (óleo e filtro de óleo do motor) |
| `trocaFiltro` | 40.000 | 48 | Manual (filtro de ar) |
| `pneusRodizio` | 10.000 | — | Manual (inspeção de pneus, sem meses) |
| `bateria` | — | 24 | Mercado (manual só pede inspeção, não define troca) |
| `palhetas` | — | 12 | Mercado (não consta no manual) |
| `arCondicionado` | 20.000 | 24 | Manual (filtro de ar da climatização) |
| `alinhamentoBalanceamento` | 10.000 | — | Mercado (não consta no manual) |
| `outro` | — | — | Nunca tem padrão |

`meses` é convertido para `intervaloDias` multiplicando por 30 (mesma unidade de dias já usada em `LembreteManutencao.intervaloDias`).

## Modelo de dados

Novo arquivo `lib/models/intervalo_manutencao.dart`:

```dart
class IntervaloManutencao {
  final int? km;
  final int? dias;
  const IntervaloManutencao({this.km, this.dias});

  bool get vazio => km == null && dias == null;

  factory IntervaloManutencao.fromMap(Map<String, dynamic> data) => IntervaloManutencao(
        km: data['km'] as int?,
        dias: data['dias'] as int?,
      );

  Map<String, dynamic> toMap() => {'km': km, 'dias': dias};

  // ==/hashCode
}
```

Novo arquivo `lib/utils/intervalo_padrao_manutencao.dart`: `const Map<TipoManutencao, IntervaloManutencao> intervalosPadraoManutencao` com a tabela acima (sem entrada para `outro`).

`Veiculo` ganha o campo `Map<TipoManutencao, IntervaloManutencao> intervalosPersonalizados` (default `{}`), serializado em `toMap()`/`fromMap()` como `Map<String, dynamic>` com a chave sendo `tipo.name`. Entra em `copyWith`, `==` e `hashCode` como os demais campos.

Nova função em `lib/utils/intervalo_padrao_manutencao.dart`:

```dart
IntervaloManutencao? intervaloEfetivo(Veiculo veiculo, TipoManutencao tipo) {
  if (tipo == TipoManutencao.outro) return null;
  return veiculo.intervalosPersonalizados[tipo] ?? intervalosPadraoManutencao[tipo];
}
```

Retorna `null` só para "Outro". Para os demais tipos, sempre retorna um `IntervaloManutencao` (explícito do veículo ou o padrão) — que pode ter `km`/`dias` nulos se o usuário limpou os campos propositalmente (`vazio == true`).

## Tela de configuração (`VeiculoFormScreen`)

Nova seção "Intervalos de manutenção" (abaixo do campo "Tipo de veículo"), com um par de `TextFormField` (km, meses — ambos opcionais, sem validação de "pelo menos um") para cada `TipoManutencao` exceto `outro`. Pré-preenchidos com `intervaloEfetivo(veiculo, tipo)` quando `_editando`; ao criar um veículo novo, pré-preenchidos direto com `intervalosPadraoManutencao[tipo]` (ainda sem veículo salvo).

Ao salvar, o mapa `intervalosPersonalizados` é reconstruído inteiro a partir do que está nos campos (todos os 8 tipos, mesmo que igual ao padrão) e enviado no `Veiculo` salvo — não há distinção entre "não mexeu" e "confirmou o padrão"; ambos viram valor explícito.

## Criação automática do lembrete

`ManutencaoProvider` passa a receber também um `LembreteRepository` no construtor (mesmo padrão do `VeiculoRepository` já injetado), e `DetalheVeiculoScreen` passa a fornecer esse repositório ao instanciar o provider.

`FirestoreRepository<T>` ganha um método de leitura pontual:

```dart
Future<List<T>> getAll(String uid, {String? veiculoId}) async {
  final snap = await collection(uid, veiculoId: veiculoId).get();
  return snap.docs.map((d) => fromMap(d.id, d.data(), veiculoId: veiculoId)).toList();
}
```

`ManutencaoProvider.adicionar()` passa a:

```dart
Future<void> adicionar(Manutencao manutencao) async {
  await _repository.add(uid, manutencao, veiculoId: _veiculoId);
  final veiculoId = _veiculoId;
  if (veiculoId == null) return;
  final veiculo = await _veiculoRepository.get(uid, veiculoId);
  if (veiculo == null) return;
  if (manutencao.kmNaData > veiculo.kmAtual) {
    await _veiculoRepository.update(uid, veiculoId, veiculo.copyWith(kmAtual: manutencao.kmNaData));
  }
  await _criarLembreteSeNecessario(veiculo, manutencao.tipo);
}

Future<void> _criarLembreteSeNecessario(Veiculo veiculo, TipoManutencao tipo) async {
  final intervalo = intervaloEfetivo(veiculo, tipo);
  if (intervalo == null || intervalo.vazio) return;
  final existentes = await _lembreteRepository.getAll(uid, veiculoId: veiculo.id);
  final jaExiste = existentes.any((l) => l.tipoManutencao == tipo);
  if (jaExiste) return;
  await _lembreteRepository.add(
    uid,
    LembreteManutencao(
      id: '',
      veiculoId: veiculo.id,
      tipoManutencao: tipo,
      intervaloKm: intervalo.km,
      intervaloDias: intervalo.dias,
      antecedenciaKm: 500,
      antecedenciaDias: 15,
      intervaloRepeticaoDias: 3,
      ativo: true,
    ),
    veiculoId: veiculo.id,
  );
}
```

`atualizar()` (edição de manutenção existente) não é alterado — continua sem criar/tocar lembretes.

## Erros

Segue o padrão já existente: qualquer falha (rede, Firestore) propaga como exceção normal de `adicionar()`; a tela (`ManutencaoFormScreen`) já trata isso com o `catch` genérico existente e mostra "Não foi possível salvar. Tente novamente." Não há tratamento especial para falha apenas na etapa de criação do lembrete — se o passo do lembrete falhar depois que a manutenção já foi salva, o erro sobe do mesmo jeito (o registro de manutenção permanece salvo; o usuário pode configurar o lembrete manualmente se necessário). Esse comportamento (não fazer rollback da manutenção se o lembrete falhar) é aceitável porque o lembrete é conveniência, não parte essencial do registro.

## Testes

- `test/models/veiculo_test.dart`: round-trip de `intervalosPersonalizados` no `toMap`/`fromMap`.
- Novo `test/utils/intervalo_padrao_manutencao_test.dart`: `intervaloEfetivo` retorna `null` para "Outro"; retorna override do veículo quando presente; cai no padrão quando ausente; retorna `vazio == true` quando o veículo tem override explícito com km/dias nulos.
- `test/providers/manutencao_provider_test.dart`: `adicionar()` cria lembrete quando não existe nenhum daquele tipo; não cria um segundo quando já existe; não cria para tipo "Outro"; não cria quando o intervalo efetivo está vazio; `atualizar()` não cria lembrete.
- `test/repositories/*_repository_test.dart`: `getAll` retorna os itens da coleção escopada por veículo.

Segue o padrão já existente no projeto (testes de model/provider/repository com fakes, sem widget tests — não há pasta `test/screens`).
