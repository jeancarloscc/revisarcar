# Progresso — Fase A: Autenticação + Navegação + CRUD de Veículos

Plano: `2026-07-06-fase-a-auth-navegacao-veiculos.md`
Execução: subagent-driven-development, adaptado **sem git** (projeto não usa controle de versão) — sem commits, sem worktree, sem diff; cada task reviewer lê os arquivos atuais listados na task em vez de um diff. Mesma adaptação usada no Plano 1.

## Tarefas concluídas

- Task 1: VeiculoRepository.remover — concluída, revisão aprovada sem ressalvas (achados menores: magic number 500 sem constante nomeada, cópia verbatim do brief; caminho de chunking >500 docs não tem teste próprio, fora do escopo pedido).
- Task 2: VeiculoProvider adicionar/atualizar/remover — concluída, revisão aprovada sem ressalvas (achado menor de estilo: teste de atualizar depende implicitamente do delay já usado para popular veiculos antes do copyWith; sem impacto, igual ao brief).
- Task 3: LoginScreen — concluída, revisão aprovada sem ressalvas (achado menor: Colors.red fixo em vez de Theme.of(context).colorScheme.error; cópia verbatim do brief).
- Task 4: VeiculoFormScreen — concluída, revisão aprovada sem ressalvas (achados menores: id vazio como placeholder no modo criar não comentado; sem autovalidateMode no Form; nenhum bloqueante).
- Task 5: ConfiguracoesScreen mínima — concluída, revisão aprovada sem ressalvas (popUntil pós-signOut confirmado correto).
- Task 6: VeiculoCard + VeiculoListScreen — concluída. Revisor achou (Important, plan-mandated) duplicação entre onTap do card e "Editar" no menu "⋮" (ambos abriam o mesmo formulário); usuário decidiu remover "Editar" do menu, deixando editar só via toque no card e o menu virando um único IconButton de exclusão. Fix aplicado, re-revisão aprovou sem ressalvas. Plano atualizado para refletir a decisão.
- Task 7: AuthGate — concluída, revisão aprovada sem ressalvas.
- Task 8: main.dart — wiring final — concluída, revisão aprovada sem ressalvas. flutter analyze: 9 achados pré-existentes (não relacionados a este plano), zero no que foi tocado. flutter test: 76/76 passando. Passo 4 (smoke test manual em dispositivo/emulador) fica pendente para o usuário — sem dispositivo disponível no ambiente do agente.

## Correção pós-plano (smoke test manual)

Durante o smoke test manual (Task 8, Passo 4), o usuário reportou "impossível salvar" ao tentar cadastrar um veículo. Debug sistemático encontrou a causa raiz: `ChangeNotifierProvider<VeiculoProvider>` estava dentro do `AuthGate`, envolvendo só a `VeiculoListScreen`. Como `VeiculoFormScreen` é aberta via `Navigator.push` (rota irmã no mesmo Navigator do `MaterialApp`, não descendente da `VeiculoListScreen`), o `VeiculoProvider` ficava fora do alcance dela — `context.read<VeiculoProvider>()` lançava `ProviderNotFoundException`, capturada silenciosamente pelo catch genérico e exibida como "Não foi possível salvar".

Correção: moveu-se o `ChangeNotifierProvider<VeiculoProvider>` para envolver o `MaterialApp` inteiro (dentro de `RevisaCarApp`, em `lib/main.dart`), condicionado ao usuário autenticado via `Consumer<AppAuthProvider>`. Isso garante que qualquer tela empurrada por `Navigator.push` — incluindo as futuras da Fase B — também enxergue o `VeiculoProvider`. O arquivo `lib/screens/auth_gate.dart` foi removido (sua lógica de decisão Login/Veículos foi absorvida por `RevisaCarApp`). `flutter analyze` (9 achados pré-existentes, nenhum novo) e `flutter test` (76/76) confirmados após a correção. Duas causas anteriores também precisaram de correção externa (fora do código) antes de chegar nesta: SHA-1 de debug não registrada no Firebase (`DEVELOPER_ERROR`) e provedor "Google" não habilitado em Authentication — ambas resolvidas.

**Confirmado pelo usuário:** login com Google e cadastro de veículo funcionando em dispositivo físico após a correção.

## Plano concluído

Todas as 8 tasks do plano "Fase A: Autenticação + Navegação + CRUD de Veículos" estão concluídas e revisadas. `flutter analyze` e `flutter test` (76/76) passando. Pendente apenas o smoke test manual (Task 8, Passo 4) — o usuário deve rodar `flutter run` num emulador/dispositivo e seguir o checklist do plano. Próximo passo depois disso: Fase B (Detalhe do veículo com abas de Manutenções/Abastecimentos/Lembretes).
