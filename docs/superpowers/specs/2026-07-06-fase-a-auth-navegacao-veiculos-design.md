# Fase A — Autenticação + Navegação + CRUD de Veículos — Design

Data: 2026-07-06

## Contexto

Primeira fase do Plano 2 (UI), que traduz em telas o backend construído no Plano 1 (Fundação: Dados e Serviços — concluído). O spec geral do app está em `docs/superpowers/specs/2026-07-05-app-manutencao-veicular-design.md`; este documento detalha só a fatia inicial, decidida por decomposição: a base sem a qual nenhuma outra tela funciona (login, esqueleto de navegação, listar/cadastrar/editar/excluir veículo).

Fases seguintes (fora deste documento): B — Detalhe do veículo com abas de Manutenções/Abastecimentos/Lembretes; C — Dashboard; D — Checklist pré-viagem; E — Configurações completa (exportação) + permissões de notificação.

## Escopo

### Telas

- **Login**: tela inicial quando `AppAuthProvider.user == null`. Botão único "Entrar com Google" (`signInWithGoogle()`, já implementado no Plano 1). Erro de login (ex: sem conexão, cancelamento) exibido inline na tela, sem travar a UI.
- **`AuthGate`**: widget raiz do app. Decide entre Login e a tela principal com base em `AppAuthProvider.user`.
- **Lista de veículos** (tela principal pós-login): escuta `VeiculoProvider` e exibe cards (ícone genérico por `tipoVeiculo` — carro ou moto — já que a foto fica fora desta fase; nome, modelo, km atual). Estado vazio orienta a cadastrar o primeiro veículo. FAB abre o formulário de novo veículo. Toque no card abre o formulário em modo edição. Cada card tem um ícone de "mais opções" que abre um menu com "Editar" e "Excluir"; "Excluir" pede confirmação (diálogo) antes de remover. Ícone de Configurações no `AppBar`.
- **Formulário de veículo** (criar/editar, mesma tela para os dois modos): campos `nome`, `modelo`, `ano`, `placa`, `kmAtual`, `tipoVeiculo` (seleção carro/moto), com validação inline (campos obrigatórios, `ano`/`kmAtual` numéricos). Sem campo de foto nesta fase — `fotoUrl` permanece nulo e a UI usa o ícone genérico como placeholder permanente até a Fase B ou posterior incluir upload.
- **Configurações (mínima)**: nesta fase, só o botão "Sair da conta" (`AppAuthProvider.signOut()`). A tela ganha o botão de exportação na Fase E, sem mudança estrutural.

Não há `BottomNavigationBar` nesta fase — a lista de veículos é a única tela de topo. A bottom nav de 3 destinos (Veículos, Dashboard, Checklist) é introduzida quando Dashboard e Checklist existirem (Fases C/D).

### Fora de escopo desta fase (confirmado)

- Foto do veículo (`image_picker` + upload Firebase Storage) — adiado.
- `BottomNavigationBar` com múltiplos destinos — adiado (só existe 1 tela de topo agora).
- Detalhe do veículo com abas, Dashboard, Checklist, exportação — fases B a E.
- Testes de widget — mantido fora do escopo, conforme o spec geral já confirmava.

## Navegação

`Navigator` padrão do Flutter (`MaterialPageRoute`, push/pop). Sem rotas nomeadas nem pacote de roteamento declarativo (`go_router` avaliado e descartado para esta fase) — não há deep link nem necessidade de reconstrução de estado de navegação a partir de URL no escopo atual.

## Tema

Mantido o `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` já presente no `main.dart` (Material 3, herdado do scaffold). Identidade visual própria não foi definida e fica para quando fizer sentido revisitar — trocar depois é só mudar o seed.

## Camada de dados — exclusão de veículo em cascata

Firestore não apaga subcoleções automaticamente ao deletar um documento pai, e implementar isso via Cloud Function ficaria fora do plano Spark (gratuito) que o projeto usa hoje (Cloud Functions v2 exige plano Blaze) — custo e infraestrutura desnecessários para um app de uso pessoal/familiar.

Solução client-side, adicionada em `VeiculoRepository`:

```
Future<void> remover(String uid, String veiculoId)
```

Implementação:
1. Para cada subcoleção do veículo (`manutencoes`, `abastecimentos`, `lembretes`, `checklistItems`), busca todos os documentos daquele `veiculoId` e apaga em lote (`WriteBatch`; se uma subcoleção puder ter mais de 500 docs — limite de um `WriteBatch` — paginar em lotes de 500).
2. Ao final, apaga o próprio documento do veículo em `users/{uid}/veiculos/{veiculoId}`.

Essa exclusão não é atômica entre as 4 subcoleções + documento do veículo (Firestore não permite transação cross-collection nesse volume) — em caso de falha no meio do processo (ex: perda de conexão), pode sobrar uma subcoleção órfã sem o veículo pai. Isso é uma limitação aceita para a v1 (mesma linha de decisões já aceitas no Plano 1 sobre condições de corrida); não há necessidade de mecanismo de retry/reconciliação agora.

## Providers

`VeiculoProvider` (hoje só expõe `selecionarVeiculo` e o stream de veículos) ganha 3 métodos novos, seguindo o mesmo padrão de `ManutencaoProvider`/`AbastecimentoProvider` do Plano 1:

- `Future<void> adicionar(Veiculo veiculo)`
- `Future<void> atualizar(String id, Veiculo veiculo)`
- `Future<void> remover(String id)` — delega para `VeiculoRepository.remover`.

## Tratamento de erros

Falhas de rede/Firestore em qualquer operação de CRUD (adicionar, atualizar, remover) exibem um `SnackBar` com mensagem de erro. No formulário, os dados preenchidos pelo usuário não são perdidos em caso de falha ao salvar (permanece na tela, permite tentar de novo).

## Testes

Sem testes de widget nesta fase, conforme já confirmado no spec geral. A lógica nova (`VeiculoRepository.remover`) ganha teste unitário com `fake_cloud_firestore`, seguindo o padrão dos testes de repositório já existentes do Plano 1 — cobrindo: veículo com subcoleções populadas é removido por completo; veículo sem nenhum registro nas subcoleções também é removido sem erro.
