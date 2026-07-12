# Fase B: Detalhe do Veículo (Manutenções/Abastecimentos/Lembretes) — Design

Data: 2026-07-10

## Contexto e objetivo

Fase A (Autenticação + Navegação + CRUD de Veículos) está completa e validada em dispositivo físico. O backend do Plano 1 (models, repositories, providers e `LembreteService`/`ConsumoService`) já existe para Manutenções, Abastecimentos e Lembretes, mas ainda não há telas para eles. Esta fase constrói a tela de Detalhe do Veículo com três abas (Manutenções, Abastecimentos, Lembretes), incluindo CRUD completo de cada tipo de registro e o cálculo/exibição de status dos lembretes.

Referência: `docs/superpowers/specs/2026-07-05-app-manutencao-veicular-design.md` (design geral do app).

## Escopo

**Dentro do escopo:**
- Tela `DetalheVeiculoScreen`: header com dados do veículo + `TabBar` com Manutenções, Abastecimentos, Lembretes.
- CRUD completo (criar/editar/excluir) de Manutenção, Abastecimento e Lembrete, cada um com sua tela de formulário.
- Cálculo e exibição do status de cada lembrete (Em dia / Alerta antecipado / Vencido), via `LembreteService` já existente.
- Ação "Marcar como resolvido" em lembretes com status Alerta/Vencido, que registra a manutenção correspondente.
- Mudança de navegação: toque no card da lista de veículos passa a abrir o Detalhe (em vez do formulário de edição do veículo).
- Configuração de localização pt-BR (`flutter_localizations`) para o `DatePicker` nativo.

**Fora do escopo (fica para fases futuras):**
- Dashboard (gráficos de consumo/gasto).
- Checklist pré-viagem.
- Foto do veículo (`image_picker`/`firebase_storage`).
- `BottomNavigationBar` e conceito de "veículo ativo" na navegação (o campo `veiculoAtivo`/`selecionarVeiculo` já existe em `VeiculoProvider` mas permanece sem uso nesta fase).
- Agendamento de notificações locais (`flutter_local_notifications`) — o campo `resolvidoEm` é gravado, mas não há série de notificação a cancelar ainda.
- Pacote `intl` — formatação de data/moeda é manual nesta fase.

## Arquitetura

### Escopo dos providers

`ManutencaoProvider`, `AbastecimentoProvider` e `LembreteProvider` (já existentes, cada um com `escutarVeiculo(veiculoId)`) são instanciados via `MultiProvider` **aninhado dentro de `DetalheVeiculoScreen`**, com `key: ValueKey(veiculo.id)`, e não em `main.dart`. Cada `create` já chama `escutarVeiculo(veiculo.id)`. Isso mantém os listeners do Firestore ativos só enquanto a tela de Detalhe está aberta, evitando leituras/conexões desnecessárias enquanto o usuário está na lista de veículos ou em Configurações. Alternativa descartada: providers globais em `main.dart` (irmãos do `VeiculoProvider`) — rejeitada por manter listeners ativos o tempo todo sem necessidade nesta fase.

### Navegação

- `VeiculoListScreen`: toque no card do `VeiculoCard` abre `DetalheVeiculoScreen(veiculo: veiculo)` (antes abria `VeiculoFormScreen`).
- `DetalheVeiculoScreen`: `AppBar` com ícone de editar (✏️) que abre `VeiculoFormScreen(veiculo: veiculo)` — mesma tela/fluxo de edição já existente da Fase A, agora acessível daqui em vez do toque no card.
- Corpo: header simples (nome, modelo/ano, placa, km atual, ícone por `tipoVeiculo`) + `TabBar`/`TabBarView` com 3 abas.
- Cada aba: `ListView` dos registros (mais recentes primeiro, por data), `FloatingActionButton` para novo registro, estado vazio orientando a cadastrar o primeiro. Toque num item abre o formulário correspondente em modo edição.
- Exclusão: cada item é um `Dismissible` (swipe); o dismiss só é confirmado após um `showDialog` de confirmação ("Excluir este registro?"); confirmando, chama `<Provider>.remover(id)`. Se o usuário cancelar o diálogo, o item retorna à posição original (`confirmDismiss` retorna `false`).

### Novas telas

- `lib/screens/detalhe_veiculo_screen.dart` — `DetalheVeiculoScreen`.
- `lib/widgets/manutencao_tab.dart`, `lib/widgets/abastecimento_tab.dart`, `lib/widgets/lembrete_tab.dart` — conteúdo de cada aba (lista + FAB), para manter `DetalheVeiculoScreen` enxuta.
- `lib/screens/manutencao_form_screen.dart` — `ManutencaoFormScreen({Manutencao? manutencao, TipoManutencao? tipoInicial, LembreteManutencao? lembreteParaResolver})`.
- `lib/screens/abastecimento_form_screen.dart` — `AbastecimentoFormScreen({Abastecimento? abastecimento})`.
- `lib/screens/lembrete_form_screen.dart` — `LembreteFormScreen({LembreteManutencao? lembrete})`.

## Campos dos formulários

**`ManutencaoFormScreen`:**
- `tipo`: dropdown do enum `TipoManutencao` (rótulos em português: Revisão, Troca de óleo, Troca de filtro, Pneus/Rodízio, Bateria, Palhetas, Ar-condicionado, Alinhamento/Balanceamento, Outro). Se `tipoInicial` for passado (fluxo de resolver lembrete) e `manutencao == null`, o dropdown já inicia com esse valor.
- `descricaoOutro`: `TextFormField`, visível e obrigatório só quando `tipo == outro`.
- `dataRealizada`: campo somente-leitura que abre `showDatePicker` (locale pt-BR), exibido como `dd/mm/aaaa` formatado manualmente.
- `kmNaData`: número obrigatório.
- `custo`: número obrigatório, decimal, label "Custo (R$)".
- `oficina`: texto obrigatório.
- `observacoes`: texto opcional, multilinha.

**`AbastecimentoFormScreen`:**
- `data`: mesmo padrão de `DatePicker`.
- `kmAtual`: número obrigatório.
- `litros`: número obrigatório, decimal.
- `valorTotal`: número obrigatório, decimal, label "Valor total (R$)".
- `tanqueCheio`: `SwitchListTile`.

**`LembreteFormScreen`:**
- `tipoManutencao`: mesmo dropdown do enum.
- `intervaloKm` / `intervaloDias`: números opcionais; validação cruzada — pelo menos um dos dois deve estar preenchido (mesma regra do `assert` do model).
- `antecedenciaKm` / `antecedenciaDias`: números opcionais, default 0.
- `intervaloRepeticaoDias`: número opcional, default 3.
- `ativo`: `SwitchListTile`, default true.

## Status de lembrete e fluxo "marcar como resolvido"

- Para cada lembrete na aba, calcula `StatusLembrete` via `LembreteService.calcularStatus`, usando `LembreteService.manutencaoMaisRecente` (lida do `ManutencaoProvider` já carregado pela aba de Manutenções, ambos escopados ao mesmo veículo) como referência de km/data, e `kmAtual`/data de hoje do veículo.
- Cada item mostra indicador visual do status: verde "Em dia", laranja "Alerta antecipado", vermelho "Vencido".
- Toque no item abre `LembreteFormScreen(lembrete: lembrete)` para editar o lembrete em si.
- Quando o status é `alertaAntecipado` ou `vencido`, o item ganha um botão extra "Marcar como resolvido", que abre `ManutencaoFormScreen(tipoInicial: lembrete.tipoManutencao, lembreteParaResolver: lembrete)`.
- Ao salvar essa manutenção com sucesso: (1) cria o registro de `Manutencao` (o que já atualiza a referência usada por `calcularProximaMeta`/`calcularStatus` automaticamente, via `manutencaoMaisRecente`), e (2) chama `LembreteProvider.atualizar(lembrete.copyWith(resolvidoEm: DateTime.now()))` antes de fechar a tela.
- Se o usuário cancelar esse formulário, nada é gravado (nem a manutenção, nem `resolvidoEm`).

## Mudanças em models

- `LembreteManutencao` ganha um método `copyWith` (não existe hoje), necessário para o fluxo de "marcar como resolvido". Segue o mesmo padrão do `copyWith` já existente em `Veiculo`.

## Localização (pt-BR)

- `pubspec.yaml`: adicionar dependência SDK `flutter_localizations`.
- `main.dart`: configurar `localizationsDelegates: GlobalMaterialLocalizations.delegates`, `supportedLocales: const [Locale('pt', 'BR')]`, `locale: const Locale('pt', 'BR')` no `MaterialApp`, nos dois branches (autenticado e não-autenticado). Sem isso, o `showDatePicker` nativo exibiria meses/dias da semana em inglês, contrariando o requisito de interface em português já fixado no design geral.

## Testes

- **Unitários (TDD, como nas fases anteriores):** `LembreteManutencao.copyWith` — teste em `test/models/lembrete_manutencao_test.dart`. Nenhuma mudança de lógica em `LembreteService`/providers além do `copyWith` — o cálculo de status já existe e já tem testes cobrindo os casos de borda.
- **Telas novas:** sem testes de widget, mesma decisão da Fase A — verificação por `flutter analyze` limpo por arquivo, mais `flutter analyze`/`flutter test` completos ao final do plano.

## Tratamento de erro

- Falhas ao salvar/excluir qualquer um dos 3 tipos de registro são tratadas com `SnackBar` genérico ("Não foi possível salvar/excluir. Tente novamente."), seguindo o padrão já usado em `VeiculoFormScreen`/`VeiculoListScreen` na Fase A.

## Execução

Sem git, mesma adaptação das fases anteriores (projeto não usa controle de versão) — nenhuma task do plano de implementação executa comandos git; cada task termina quando testes/análise passam.

## Fora de escopo (confirmado)

- Dashboard, Checklist pré-viagem, foto do veículo, `BottomNavigationBar`, conceito de "veículo ativo" na navegação.
- Agendamento de notificações locais (`flutter_local_notifications`).
- Pacote `intl` (formatação de data/moeda é manual nesta fase).
