# Redesign visual do app (baseado em protótipo Figma Make) — Design

Data: 2026-07-11

## Contexto e objetivo

O app RevisaCar (Flutter/Firebase, Material 3) está funcional mas com visual genérico: listas simples, sem tema próprio, sem hierarquia visual. O usuário gerou, com o Figma Make, um protótipo de referência completo (React/Vite) cobrindo todas as telas do app com um novo visual. Este spec traduz esse protótipo para Flutter, mantendo a arquitetura de dados/providers/repositories já existente — é uma mudança de **camada visual apenas**, nenhuma lógica de negócio muda.

Referência: protótipo em `/tmp/claude-1000/-home-jean-Projects-revisacar/e401376f-b8f9-40b4-b4d2-beb905131e6c/scratchpad/figma-redesign/src/app/App.tsx` (arquivo único React com todas as telas, usado só como referência visual — não é copiado, é traduzido para widgets Flutter equivalentes).

## Escopo

**Dentro do escopo:** redesign visual de todas as telas existentes (Login, Lista de veículos, Detalhe do veículo com as 3 abas, todos os formulários, Configurações), novo sistema de tema claro/escuro com tokens de cor do protótipo, tipografia (Barlow Condensed + Inter via `google_fonts`), catálogo de ícone+cor por tipo de manutenção, acordeão para a seção de intervalos de manutenção no formulário de veículo, toggle de tema escuro em Configurações persistido em `SharedPreferences`.

**Fora do escopo:** qualquer mudança de modelo de dados, providers, repositories ou regras de negócio (auto-criação de lembrete, cálculo de status, etc. — tudo isso já existe e não muda). Ilustrações/imagens customizadas (só ícones do Material). Onboarding ou telas novas que não existem hoje. Testes de widget (o projeto não tem essa camada de teste; verificação continua sendo `flutter analyze` + teste manual).

## Design tokens

Novo arquivo `lib/theme/app_theme.dart` exportando `ThemeData appThemeLight` e `ThemeData appThemeDark`, usando `ColorScheme` explícito (não `fromSeed`) com os valores exatos do protótipo:

**Claro:**
- background `#F3E6D7`, foreground `#162936`, card `#FFFCF8`, secondary `#EEDDD2`, muted `#E8D5C4`, accent/primary de destaque `#CE9D78`, destructive `#C0392B`, border `rgba(22,41,54,0.13)`.

**Escuro:**
- background `#162936`, foreground `#F3E6D7`, card `#25343E`, secondary `#1D2F3A`, muted `#25343E`, accent `#CE9D78` (mesma cor nos dois temas), destructive `#E74C3C`, border `rgba(243,230,215,0.11)`.

**Cores de status de lembrete** (usadas em cards/pills, iguais nos dois temas):
- Em dia: texto `#16A34A`, fundo `#F0FDF4`.
- Alerta: texto `#EA580C`, fundo `#FFF7ED`.
- Vencido: texto `#DC2626`, fundo `#FEF2F2`.

**Tipografia:** `google_fonts` — `GoogleFonts.barlowCondensedTextTheme()` para títulos (`headlineLarge`/`headlineMedium`, peso `FontWeight.w900`, `letterSpacing` levemente negativo), `GoogleFonts.interTextTheme()` como base do `textTheme`. Adicionar dependência `google_fonts` ao `pubspec.yaml`.

**Forma:** `RoundedRectangleBorder` com `borderRadius: BorderRadius.circular(16)` para cards, `12` para inputs/botões menores, consistente com o `radius: 0.875rem` (14px) do protótipo — helpers de constantes em `app_theme.dart` (`kCardRadius = 16.0`, `kInputRadius = 12.0`).

## Catálogo ícone + cor por tipo de manutenção

Novo arquivo `lib/utils/tipo_manutencao_visual.dart`, extension `TipoManutencaoVisual on TipoManutencao` com getters `icon` (IconData) e `cor` (Color):

| TipoManutencao | Ícone | Cor |
|---|---|---|
| `revisao` | `Icons.assignment_turned_in` | `#059669` |
| `trocaOleo` | `Icons.water_drop` | `#F07810` |
| `trocaFiltro` | `Icons.air` | `#4A90D9` |
| `pneusRodizio` | `Icons.circle` | `#6B7280` |
| `bateria` | `Icons.battery_charging_full` | `#D97706` |
| `palhetas` | `Icons.cleaning_services` | `#0891B2` |
| `arCondicionado` | `Icons.ac_unit` | `#0EA5E9` |
| `alinhamentoBalanceamento` | `Icons.tune` | `#7C3AED` |
| `outro` | `Icons.more_horiz` | `#64748B` |

Usado em: cards de manutenção (histórico e "próximas"), cards de lembrete, seletor de tipo nos formulários, acordeão de intervalos no formulário de veículo.

## Tema escuro (toggle manual)

Novo `lib/providers/theme_mode_provider.dart`: `ChangeNotifier` simples com `ThemeMode themeMode` (default `ThemeMode.light`), método `alternar()` que inverte e persiste um `bool` em `SharedPreferences` (chave `'tema_escuro'`), lendo o valor salvo no construtor. Registrado em `main.dart` como `ChangeNotifierProvider<ThemeModeProvider>` no `MultiProvider` raiz (ao lado do `AppAuthProvider`), e `MaterialApp` passa a usar `theme: appThemeLight, darkTheme: appThemeDark, themeMode: context.watch<ThemeModeProvider>().themeMode`.

## Telas — comportamento visual (arquitetura/navegação inalterada, só a camada visual muda)

- **`lib/screens/login_screen.dart`**: badge quadrado arredondado com gradiente (`#25343E`→`#162936`) e ícone de chave inglesa (`Icons.build`), título "RevisaCar" em Barlow Condensed grande/preto, subtítulo, botão "Entrar com Google" como card branco com sombra leve — mantém o ícone atual (`Icons.login`), sem adicionar logo/asset customizado do Google (fora do escopo, sem ilustrações customizadas).
- **`lib/widgets/veiculo_card.dart`**: troca `ListTile` simples por card com avatar circular/arredondado colorido por tipo de veículo (navy p/ carro, tom avermelhado p/ moto), nome em negrito, modelo+ano em cinza, pill de km com ícone de velocímetro (`Icons.speed`), pill de alerta (contagem de lembretes vencidos/em alerta daquele veículo, vermelho se tiver vencido, laranja se só alerta) — requer acesso a `LembreteProvider`/cálculo de status por veículo (ver nota de arquitetura abaixo).
- **`lib/screens/veiculo_list_screen.dart`**: título grande Barlow Condensed, FAB com gradiente.
- **`lib/screens/detalhe_veiculo_screen.dart`**: cabeçalho vira um card com gradiente (navy p/ carro, vermelho p/ moto) e pills (km atual, contagem vencidos, contagem alertas — via `LembreteService`); `NavigationBar` já existente ganha `indicatorColor`/cor de destaque cobre.
- **`lib/widgets/manutencao_tab.dart`**: bloco "Próximas manutenções" (já existe, texto simples) vira lista horizontal rolável de cards compactos com borda esquerda colorida por status e ícone do tipo; histórico ganha ícone colorido por tipo em cada item.
- **`lib/widgets/abastecimento_tab.dart`**: adiciona 2 cards de estatística no topo (total gasto, total de litros) antes do histórico; itens do histórico ganham ícone (`Icons.local_gas_station`, cor de destaque).
- **`lib/widgets/lembrete_tab.dart`**: cards com borda esquerda colorida por status, ícone do tipo, pills mostrando o intervalo configurado (km/meses), botão "Marcar como feito"/resolvido com cor do status.
- **`lib/screens/manutencao_form_screen.dart`**: seletor de tipo vira grade 2 colunas de botões com ícone+label (ao invés de dropdown), destaque visual no tipo selecionado; demais campos com rótulo pequeno em caixa alta acima do input; botão salvar fixo embaixo com gradiente.
- **`lib/screens/abastecimento_form_screen.dart`**: mesmo padrão de campos rotulados + botão fixo; card de "total estimado" (litros × valor) quando ambos preenchidos.
- **`lib/screens/lembrete_form_screen.dart`**: mesmo padrão de campos rotulados + botão fixo (o protótipo não cobre esta tela — segue o mesmo padrão visual das outras).
- **`lib/screens/veiculo_form_screen.dart`**: campos básicos com o mesmo padrão rotulado; seletor de tipo carro/moto como 2 botões lado a lado; seção "Intervalos de manutenção" reestruturada como **acordeão**, usando `ExpansionTile` (widget nativo do Material) para cada um dos 8 tipos (exceto Outro): título colapsado mostra ícone, label e resumo ("10.000 km · 12 meses" ou "Não configurado"), e o conteúdo expandido revela os 2 campos (km, meses) lado a lado. Estado de expansão fica a cargo do próprio `ExpansionTile` (não precisa de estado próprio no widget pai).
- **`lib/screens/configuracoes_screen.dart`**: card de usuário (nome/e-mail do `AppAuthProvider`), seção "Aparência" com switch de tema escuro (liga em `ThemeModeProvider`), seção "Seus dados" com contagem de veículos/manutenções/abastecimentos (via providers), botão "Sair da conta" com estilo destrutivo.

### Nota de arquitetura: badge de alerta no card de veículo

Hoje `VeiculoCard`/`VeiculoListScreen` não têm acesso a lembretes (só a `VeiculoProvider`). Para mostrar a contagem de alerta/vencido por veículo na lista, `VeiculoListScreen` precisa, para cada veículo, buscar seus lembretes e manutenções mais recentes e calcular status via `LembreteService` — isso requer uma consulta pontual (não um stream ativo por veículo, para não abrir N listeners na tela de lista). Usar `LembreteRepository.getAll`/`ManutencaoRepository.getAll` (já existentes) sob demanda ao construir cada card, com um `FutureBuilder` por card (aceitável para uma lista de poucos veículos; sem novo campo em `Veiculo`).

## Testes

Sem testes de widget (convenção já estabelecida no projeto). Verificação: `flutter analyze` limpo em todos os arquivos tocados, `flutter test` completo sem regressão (nenhuma lógica de providers/models muda), e teste manual no app (rodar e navegar por todas as telas, alternar tema claro/escuro).
