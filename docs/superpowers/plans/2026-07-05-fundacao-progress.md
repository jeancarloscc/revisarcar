# Progresso — Fundação: Dados e Serviços

Plano: `2026-07-05-fundacao-dados-e-servicos.md`
Execução: subagent-driven-development, adaptado **sem git** (projeto não usa controle de versão) — sem commits, sem worktree, sem diff; cada task reviewer lê os arquivos atuais listados na task em vez de um diff.

## Tarefas concluídas

- Task 1: Dependências do projeto — concluída, revisão aprovada sem ressalvas.
- Task 2: Restringir plataformas a Android/iOS — concluída, revisão aprovada sem ressalvas.
- Task 5: Modelo Veiculo — concluída, revisão aprovada sem ressalvas.
- Task 6: Modelo Manutencao — concluída, revisão aprovada (1 sugestão menor não bloqueante: mensagem de erro de parseFirestoreDate poderia incluir o valor recebido).
- Task 7: Modelo Abastecimento — concluída, revisão aprovada (imprecisões triviais no relatório do implementador, não no código).
- Task 8: Modelo LembreteManutencao — concluída, revisão aprovada sem ressalvas.
- Task 9: Modelo ChecklistItem — concluída, revisão aprovada sem ressalvas.
- Task 10: ConsumoService 4a — concluída, revisão aprovada (achado menor: guarda extra `atual.litros <= 0` não estava explícita na spec, mas é defensiva e correta; aceita como está).
- Task 11: ConsumoService 4b/4c — concluída, revisão aprovada sem ressalvas.
- Task 14: LembreteService — próxima meta + manutencaoMaisRecente — concluída, revisão aprovada (achado menor de estilo em manutencaoMaisRecente, sort mutável descartável; sem impacto funcional).
- Task 12: ConsumoService 4d — concluída, revisão aprovada (achado menor: faltam testes explícitos para kmTotal/litrosTotais <= 0, código já trata corretamente).
- Task 15: LembreteService — status — concluída, revisão aprovada sem ressalvas.
- Task 13: ConsumoService 4e/4f — concluída. Revisor achou duplicação estrutural (Importante, mandada pelo plano) entre consumoPeriodo e custoPorKmPeriodo; usuário decidiu extrair helper compartilhado (_periodoValido); fix aplicado, 16/16 testes passando.
- Task 16: ExportService — concluída. Revisor achou (Crítico) lembretesCsv sem teste e (Importante) escaping de aspas/quebra de linha sem teste — gaps do próprio plano, não do implementador. Fix adicionou 4 testes (5→9), re-revisão aprovou sem ressalvas.
- Task 17: FirestoreRepository + VeiculoRepository — concluída, revisão aprovada (2 achados menores: unused_import cosmético em teste, e nota de atenção sobre uso real de veiculoId nas Tasks 18/19 — nenhum bloqueia).
- Task 18: ManutencaoRepository + AbastecimentoRepository — concluída. Revisor achou 2 pontos Importante (mandados pelo plano): assert() de veiculoId é removido em release (risco de doc órfão silencioso); teste de isolamento v1/v2 não replicado em Abastecimento. Usuário decidiu manter ambos como estavam (aceita os riscos apontados). Sem alteração de código.
- Task 19: LembreteRepository + ChecklistRepository — concluída, revisão aprovada. Revisor notou suíte completa falhando em test/providers/auth_provider_test.dart (colisão de nome AuthProvider com firebase_auth) — causado pela Task 20, rodando em paralelo, não por esta task.
- Task 20: AppAuthProvider — concluída. Implementador achou 2 problemas reais durante o trabalho: (1) colisão de nome AuthProvider com firebase_auth — usuário decidiu renomear para AppAuthProvider (plano atualizado); (2) API do google_sign_in 7.2.0 real é diferente da presumida no plano (GoogleSignIn.instance.initialize()+authenticate() em vez de construtor+signIn()) — implementador adaptou corretamente, revisor verificou linha a linha contra o pacote instalado. Aprovado (1 achado menor: doc comment com nome antigo, corrigido diretamente).
- Task 21: VeiculoProvider — concluída, revisão aprovada (achados menores: falta teste do fallback "veículo salvo sumiu da lista" e teste de dispose(); código já correto, sem bloqueio).
- Task 22: ManutencaoProvider + AbastecimentoProvider — concluída. ManutencaoProvider já estava pronto de uma sessão anterior; AbastecimentoProvider implementado e revisado sem ressalvas.
- Task 23: LembreteProvider + ChecklistProvider — concluída, revisão aprovada (achado menor: resetarTodos() faz updates sequenciais em vez de batch write — ineficiente mas correto e conforme a spec; não bloqueante). Suíte completa: 69/69 testes passando.
- Task 24: Atualização automática de Veiculo.kmAtual (Decisão 3) — concluída, revisão aprovada. ManutencaoProvider e AbastecimentoProvider passaram a exigir VeiculoRepository no construtor; adicionar() faz bump de kmAtual só quando o km novo é maior. Achados menores (não bloqueantes): race de read-modify-write em chamadas concorrentes de adicionar() para o mesmo veículo (limitação aceita do design da spec, não bug); falta teste simétrico "não reduz" em abastecimento_provider_test.dart (brief não pediu). Suíte completa: 72/72 testes passando, flutter analyze sem erros.

- Task 3: Projeto Firebase e `firebase_options.dart` — concluída manualmente pelo usuário (login interativo + `flutterfire configure`). `firebase.json` e `lib/firebase_options.dart` gerados para o projeto `revisacar-veicular`.
- Task 4: Inicializar Firebase no `main.dart` — concluída. `main.dart` substituído pela inicialização do Firebase (`Firebase.initializeApp` + persistência do Firestore habilitada) e `RevisaCarApp`; `test/widget_test.dart` (teste padrão do contador) removido. `flutter analyze` sem erros (só infos/warning pré-existentes, não relacionados); suíte completa 71/71 testes passando.

## Plano concluído

Todas as tasks do plano "Fundação: Dados e Serviços" (1-24) estão concluídas e revisadas. Próximo passo: iniciar o Plano 2 (UI).
