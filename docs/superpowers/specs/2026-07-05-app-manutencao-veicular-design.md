# App de Manutenção de Carro — Design

Data: 2026-07-05

## Contexto e objetivo

App Flutter para controle de manutenção veicular (carros e motos), uso diário. **Revisão desta seção (rodada 3):** o app deixou de ser local-only — agora usa Firebase como backend, para (a) não perder o histórico se o aparelho for perdido/trocado e (b) permitir que outras pessoas (ex: familiares) usem o app com suas próprias contas, cada uma com seus próprios veículos e dados totalmente isolados (sem compartilhamento entre contas na v1). Plataformas alvo: **Android e iOS apenas** (os diretórios linux/macos/windows/web do scaffold padrão serão removidos). Interface em **Português (Brasil)**, com datas em `dd/mm/aaaa` e moeda em `R$`.

## Stack técnica

- Flutter (SDK `^3.12.2`, já configurado no `pubspec.yaml`)
- Gerenciamento de estado: `provider` (ChangeNotifier / StreamProvider)
- Backend: **Firebase**
  - `firebase_core`
  - `firebase_auth` + `google_sign_in` (login)
  - `cloud_firestore` (dados, com persistência offline nativa — ver Decisão 0)
  - `firebase_storage` (foto do veículo)
- `image_picker` (selecionar/tirar foto do veículo)
- Notificações locais agendadas: `flutter_local_notifications` (+ `timezone` para `zonedSchedule`) — permanece **local**, não depende do Firebase
- Gráficos: `fl_chart`
- Exportação: `path_provider` + `share_plus`
- Formatação: `intl` (datas e moeda pt-BR)

## Arquitetura em camadas

```
lib/
  models/          — Veiculo, Manutencao, LembreteManutencao, Abastecimento, ChecklistItem
  repositories/    — FirestoreRepository<T> genérico + repositórios por entidade (mapeiam doc <-> model)
  services/        — ConsumoService, LembreteService, ExportService (continuam Dart puro, sem depender do Firestore)
  providers/       — AuthProvider, VeiculoProvider, ManutencaoProvider, AbastecimentoProvider, LembreteProvider, ChecklistProvider
  screens/         — login, lista_veiculos, detalhe_veiculo (tabs), formulários, dashboard, checklist, configuracoes
  widgets/         — componentes reutilizáveis (cards, campos de formulário compartilhados)
test/
  services/        — testes unitários do ConsumoService e LembreteService (Dart puro, não tocam Firestore)
```

Cada provider (exceto `AuthProvider`) escuta um `Stream` do Firestore já filtrado pelo `uid` do usuário logado e pelo veículo ativo (guardado em memória no `VeiculoProvider`, com o último veículo selecionado lembrado via `shared_preferences`). Exceções: `ExportService`, que opera sobre todos os veículos do usuário, e o `ChecklistProvider`, que também é escopado por `veiculoId` (checklist por veículo, decisão confirmada).

## Estrutura de dados no Firestore

Todas as coleções vivem sob o documento do usuário, garantindo isolamento total por conta (nenhuma regra de segurança precisa cruzar dados entre usuários):

```
users/{uid}/veiculos/{veiculoId}
users/{uid}/veiculos/{veiculoId}/manutencoes/{manutencaoId}
users/{uid}/veiculos/{veiculoId}/abastecimentos/{abastecimentoId}
users/{uid}/veiculos/{veiculoId}/lembretes/{lembreteId}
users/{uid}/veiculos/{veiculoId}/checklistItems/{itemId}
```

Regra de segurança (Firestore Rules), resumo: `allow read, write: if request.auth != null && request.auth.uid == uid;` em qualquer profundidade sob `users/{uid}` — nada além disso é necessário já que não há compartilhamento entre contas na v1.

Foto do veículo: `firebase_storage` em `users/{uid}/veiculos/{veiculoId}/foto.jpg`, com regra equivalente (só o dono lê/escreve). A Firestore guarda apenas a `fotoUrl` (download URL) no documento do veículo.

## Modelo de dados

```
Veiculo:
  id, nome, modelo, ano, placa, kmAtual, tipoVeiculo, fotoUrl
  # tipoVeiculo ∈ {carro, moto}
  # fotoUrl: URL da foto no Firebase Storage, nullable (veículo pode não ter foto ainda)

Manutencao:
  id, veiculoId, tipo, descricaoOutro, dataRealizada, kmNaData, custo, oficina, observacoes
  # tipo ∈ {revisao, troca_oleo, troca_filtro, pneus_rodizio, bateria, palhetas,
  #         ar_condicionado, alinhamento_balanceamento, outro}
  # descricaoOutro só é preenchido quando tipo == outro

LembreteManutencao:
  id, veiculoId, tipoManutencao, intervaloKm, intervaloDias,
  antecedenciaKm, antecedenciaDias, intervaloRepeticaoDias, ativo, resolvidoEm

Abastecimento:
  id, veiculoId, data, kmAtual, litros, valorTotal, tanqueCheio

ChecklistItem:
  id, veiculoId, descricao, ordem, verificado
```

Regras de integridade:
- `Manutencao.tipo == outro` exige `descricaoOutro` não vazio (validado no formulário).
- `LembreteManutencao` exige pelo menos um de `intervaloKm` / `intervaloDias` preenchido (regra "o que vencer primeiro" quando ambos preenchidos).

## Decisões de design

### 0. Firestore como fonte de dados, com persistência offline nativa (em vez de sqflite + sync manual)

Em vez de manter `sqflite` local e escrever uma camada de sincronização com o Firestore (duas fontes de verdade, merge de conflitos, fila de retry manual), a v1 usa **apenas o Firestore** como fonte de dados, com `Settings(persistenceEnabled: true)` (ligado por padrão no mobile). O SDK do Firestore já resolve sozinho o que motivou a pergunta original ("app local, sem depender de internet"): leituras funcionam do cache local mesmo offline, escritas feitas offline ficam enfileiradas e sincronizam automaticamente quando a conexão volta. Isso elimina uma camada inteira de complexidade (sync manual) sem abrir mão do uso offline no dia a dia (garagem, oficina sem sinal, etc).

Trade-off aceito: o app passa a depender de um projeto Firebase configurado (plano Spark/gratuito é suficiente para uso pessoal/familiar) e de login para funcionar — não há mais modo "sem conta". Isso é consistente com o pedido de multi-usuário.

### 1. Autenticação (Firebase Auth + Google Sign-In)

Único método de login na v1: **Google Sign-In**. Um `AuthProvider` expõe o usuário atual (`User?`) e um `AuthGate` na raiz do app mostra a tela de Login quando `user == null`, ou a navegação principal quando autenticado. Sign-out disponível na tela de Configurações. Sem recuperação de senha ou fluxo de e-mail/senha a implementar, já que o login é delegado inteiramente ao Google.

### 2. Foto do veículo

Campo `fotoUrl` em `Veiculo`, preenchido via `image_picker` (câmera ou galeria) no formulário de cadastro/edição do veículo, com upload para o Firebase Storage. Enquanto `fotoUrl` for nulo, a UI mostra um ícone genérico baseado em `tipoVeiculo` (carro ou moto) como placeholder — não há busca de imagens de terceiros nem acervo de modelos por marca, evitando qualquer questão de direito de imagem.

### 3. Atualização de `Veiculo.kmAtual`

Atualizado automaticamente para o maior valor entre o atual e o km informado em qualquer novo registro de manutenção ou abastecimento daquele veículo. Também editável manualmente na tela do veículo (ex: correção de digitação). Isso garante que o cálculo de "próxima manutenção" sempre parta do km mais recente conhecido.

### 4. Ordenação para cálculos de consumo e lembretes

Todos os cálculos que dependem de "registro anterior" (ConsumoService e LembreteService) ordenam por **data** do registro, não por ordem de inserção — permite cadastrar um abastecimento ou manutenção atrasada sem quebrar os cálculos. Em caso de empate de data, desempate por km.

### 5. Motor de lembretes e notificações (reativo, sem worker em background)

O `LembreteService` recalcula a data/km-alvo de cada lembrete ativo sempre que algo relevante muda: app inicia, veículo ativo muda, uma manutenção é registrada/editada, ou um lembrete é criado/editado. A cada recálculo, reagenda as notificações locais correspondentes via `flutter_local_notifications` usando **alarmes exatos** (`zonedSchedule` com `AndroidScheduleMode.exactAllowWhileIdle`), conforme decidido — o app solicitará a permissão "Alarmes e lembretes" no Android 12+ na primeira vez que um lembrete for ativado.

Não há tarefa periódica em background (`workmanager` ou similar): como o km só muda quando o usuário insere dados, recalcular nesses eventos é suficiente — uma tarefa em background rodaria sem nada de novo para calcular.

**Cálculo da próxima ocorrência:** para cada tipo de manutenção com lembrete ativo, busca a manutenção mais recente daquele tipo (por data) para obter `kmNaData` e `dataRealizada` de referência:
- Meta por km: `kmNaData_referencia + intervaloKm`
- Meta por tempo: `dataRealizada_referencia + intervaloDias`
- Se ambos configurados, o lembrete dispara assim que **qualquer uma** das duas condições (km ou data) for atingida — "o que vencer primeiro"
- Se não há manutenção anterior daquele tipo, a referência é a data de cadastro do veículo / km de cadastro.

**Alerta de antecedência:** notificação inicial disparada quando `kmAtual >= meta_km - antecedenciaKm` OU `hoje >= meta_data - antecedenciaDias` (o que ocorrer primeiro), com texto diferenciando "lembrete antecipado" de "vencido".

**Notificação recorrente de lembrete ignorado:** a partir do momento em que a meta é atingida (não apenas a antecedência), agenda-se uma série de notificações repetidas a cada `intervaloRepeticaoDias` (campo configurável por lembrete). A série é cancelada assim que o usuário marca o lembrete como resolvido (grava `resolvidoEm` e, se o lembrete for recorrente, prepara o próximo ciclo a partir da manutenção registrada).

### 6. Registro de abastecimento e `ConsumoService`

Camada de serviço pura (sem dependência de UI/DB direta — recebe listas de `Abastecimento` já carregadas), com as seguintes funções e testes unitários:

**a) Consumo por abastecimento (km/l)**
- Calculável apenas entre dois abastecimentos consecutivos (por data) do mesmo veículo onde **ambos** têm `tanqueCheio == true`.
- `consumo = (kmAtual - kmAbastecimentoAnteriorCheio) / litrosAbastecidosAgora`
- Se o abastecimento anterior mais próximo não foi tanque cheio, resultado é `null` (indisponível) — não estima.

**b) Custo por litro**
- `custoPorLitro = valorTotal / litros`

**c) Custo por km rodado (entre abastecimentos consecutivos, tanque cheio ou não)**
- `custoPorKm = valorTotal / (kmAtual - kmAbastecimentoAnterior)`

**d) Consumo agregado por período (semana/mês)**
- `consumoPeriodo = kmTotalRodadoNoPeriodo / litrosTotaisNoPeriodo`, onde:
  - `kmTotalRodadoNoPeriodo = odometro(último abastecimento do período) - odometro(primeiro abastecimento do período)`
  - `litrosTotaisNoPeriodo = soma(litros de todos os abastecimentos do período, exceto o primeiro)`
- Requer no mínimo 2 abastecimentos no período; caso contrário, resultado `null` (indisponível).
- **Não** faz média simples dos consumos individuais (distorce com tanques de tamanhos diferentes).

**e) Gasto agregado por período**
- `gastoPeriodo = soma(valorTotal de todos os abastecimentos no período)`

**f) Custo por km no período**
- `custoPorKmPeriodo = gastoPeriodo / kmTotalRodadoNoPeriodo`

### 7. Dashboard

- Gráfico de consumo (km/l) por semana e por mês (`fl_chart`, usando 6d).
- Gráfico de gasto com combustível por semana e por mês (6e).
- Indicador de custo por km rodado no período (6f).
- Resumo: total gasto em combustível vs. total gasto em manutenção no período selecionado (soma de `Manutencao.custo` no mesmo intervalo).
- Seletor de período no topo do dashboard (esta semana / este mês / mês anterior / intervalo customizado).

### 8. Checklist pré-viagem (por veículo)

- Lista de `ChecklistItem` (descrição + ordem) editável: adicionar, remover, reordenar.
- Itens padrão sugeridos na criação de um veículo novo: óleo, pneus, água do radiador, freio, estepe, triângulo — usuário pode editar livremente depois.
- Marcar/desmarcar `verificado` por item.
- Ao entrar na tela novamente após todos os itens estarem marcados (ou via botão "Nova viagem"), reseta todos os `verificado` para `false` — não mantém histórico.

### 9. Exportação de dados

- `ExportService` lê todos os documentos do usuário logado no Firestore (todos os veículos e subcoleções) e gera 4 arquivos CSV, colunas em `snake_case`, datas em ISO 8601 (`aaaa-mm-dd`) para facilitar `pandas.read_csv(parse_dates=[...])`:
  - `veiculos.csv`: id, nome, modelo, ano, placa, km_atual
  - `manutencoes.csv`: id, veiculo_id, tipo, descricao_outro, data_realizada, km_na_data, custo, oficina, observacoes
  - `abastecimentos.csv`: id, veiculo_id, data, km_atual, litros, valor_total, tanque_cheio
  - `lembretes.csv`: id, veiculo_id, tipo_manutencao, intervalo_km, intervalo_dias, antecedencia_km, antecedencia_dias, intervalo_repeticao_dias, ativo, resolvido_em
- `ChecklistItem` fica fora do export — estado efêmero (resetado a cada viagem), sem valor de série histórica.
- Fluxo: tela de Configurações (nova, minimalista) → botão "Exportar dados" → `path_provider` grava os CSVs num diretório temporário → `share_plus` abre o share sheet do sistema (usuário escolhe destino: e-mail, Drive, etc). Nenhum dado é enviado a serviço externo pelo app — o compartilhamento é uma ação explícita do usuário no share sheet do SO.

## Telas e navegação

- **Login**: tela inicial quando não autenticado; botão único "Entrar com Google"; erro de login exibido inline (ex: sem conexão).
- **Lista de veículos** (home após login): cards com foto (ou ícone genérico por `tipoVeiculo`), nome/apelido, modelo, km atual; toque abre detalhe; botão para cadastrar novo veículo; estado vazio orienta a cadastrar o primeiro veículo.
- **Detalhe do veículo**: header com dados do veículo (editável, incluindo foto) + `TabBar` com abas: Manutenções, Abastecimentos, Lembretes.
  - Cada aba lista os registros (mais recente primeiro) com FAB para novo registro; toque num item abre formulário de edição.
- **Formulários** (manutenção, abastecimento, lembrete, veículo, checklist item): validação inline, campos conforme modelo de dados.
- **Dashboard**: acessível por ícone na lista de veículos ou bottom navigation; gráficos e indicadores do item 7, sempre referentes ao veículo ativo.
- **Checklist pré-viagem**: acessível por ícone na lista de veículos ou bottom navigation; lista do veículo ativo.
- **Configurações**: botão de exportação de dados e botão "Sair da conta" (sign-out).

Navegação: `AuthGate` na raiz decide entre Login e o app principal. Dentro do app: `BottomNavigationBar` com 3 destinos (Veículos, Dashboard, Checklist) + Configurações acessível via ícone no AppBar. Troca de veículo ativo feita a partir da lista de veículos ou de um seletor no AppBar do Dashboard/Checklist.

## Notificações — permissões e tratamento de erro

- Solicita permissão de notificação (iOS sempre; Android 13+ `POST_NOTIFICATIONS`) na primeira vez que o usuário ativa qualquer lembrete.
- Solicita permissão de alarme exato (Android 12+, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`) no mesmo momento; se negada, o lembrete continua funcionando com `AndroidScheduleMode.inexactAllowWhileIdle` como fallback (aviso in-app de que o horário pode variar).
- Falhas ao agendar (ex: permissão revogada depois) não travam o app — são logadas e o lembrete aparece com indicador visual de "notificação não agendada" na tela de Lembretes, sem impedir o cálculo/exibição da meta.

## Testes

- **Unitários (obrigatório, item 6):** `ConsumoService` — casos para cada função (a–f), incluindo bordas: sem abastecimento anterior, abastecimento anterior não é tanque cheio, período com 0 ou 1 abastecimento, datas fora de ordem de inserção.
- **Unitários adicionais:** `LembreteService` — cálculo de próxima meta (km, tempo, ambos), disparo de antecedência, agendamento de série de repetição.
- Sem testes de widget/integração no escopo inicial (fora do pedido original); pode ser adicionado depois se desejado.

## Fora de escopo (confirmado)

- Upload/anexo de foto de nota fiscal (a foto do veículo em si está dentro do escopo — ver Decisão 2).
- Controle de documentação (IPVA, licenciamento, seguro, CNH).
- Exportação em PDF (CSV cobre a necessidade de análise de dados).
- Compartilhamento de veículos entre contas diferentes (ex: família toda editando o mesmo carro) — cada conta só vê os próprios dados na v1.
- Login por e-mail/senha ou outros provedores além de Google.
- Busca automática de imagem real do modelo/marca do veículo na internet.
- Suporte a linux/macos/windows/web (scaffold será restrito a Android/iOS).
