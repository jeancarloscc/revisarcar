# Fidelidade ao mockup "Redesign do app RevisaCar" — Design

Data: 2026-08-02

## Contexto e objetivo

O usuário compartilhou 7 PDFs exportados do Figma (`~/Downloads/Sem título (1)/Redesign do app RevisaCar[-N].pdf`) cobrindo Login, Lista de veículos, Detalhe do veículo (abas Manutenções/Abastecimentos/Lembretes), Calculadora de viagem e o formulário Nova Manutenção. Comparação com o código atual mostrou que o app já implementa a mesma linguagem visual (paleta, tipografia, cards) descrita em `docs/superpowers/specs/2026-07-11-redesign-visual-design.md` — a maior parte das telas já bate com o mockup. Este spec cobre só os **gaps concretos** encontrados na comparação tela a tela; é uma mudança de camada visual/comportamental pontual, sem alterar modelos, providers ou repositories.

## Escopo

**Dentro do escopo:**
1. `lib/widgets/veiculo_card.dart` — trailing com ícone de exclusão com fundo circular + chevron.
2. `lib/widgets/lembrete_tab.dart` — chips de intervalo configurado, botão "Marcar como feito" sempre visível, remoção do link "Editar regra".
3. `lib/screens/calculadora_combustivel_screen.dart` — reordenar campos (Consumo antes de Preço), hint persistente "Média registrada do veículo" com ação "Usar X km/L".
4. `lib/screens/manutencao_form_screen.dart` e `lib/screens/abastecimento_form_screen.dart` — reordenar campos do formulário de manutenção; botão Salvar fixo no rodapé com gradiente em ambos os formulários (consistência — o spec de 2026-07-11 já previa isso para os dois, nunca foi implementado).

**Fora do escopo:** qualquer mudança de modelo de dados, cálculo ou regra de negócio; a tela de Login (já bate com o mockup, exceto o link "Simular erro de login", que é um controle interno do protótipo Figma para alternar estados de demonstração — não é uma feature real, não será implementado); abas Manutenções e Abastecimentos (já batem com o mockup); telas Config., +Abastecimento e +Veículo (não fizeram parte do export de PDFs).

## Mudanças por tela

### `veiculo_card.dart`

O `trailing` do `ListTile` passa de um único `IconButton` para uma `Row` com dois elementos: o botão de exclusão ganha fundo circular (`CircleAvatar`-like, `color: colorScheme.error.withValues(alpha: 0.12)`, ícone `Icons.delete_outline` cor `colorScheme.error`, tamanho 36) e, ao lado, `Icon(Icons.chevron_right, color: Colors.grey.shade400)` — o chevron é só indicativo (não recebe `onTap` próprio; o tap continua no `ListTile.onTap` existente, que já leva ao detalhe).

### `lembrete_tab.dart`

- **Chips de intervalo**: novo `Wrap` logo abaixo das linhas "Próxima"/"Prazo", com chips (`Container` arredondado, fundo `colorScheme.secondary`, texto cinza escuro) mostrando `'cada ${lembrete.intervaloKm} km'` (quando `intervaloKm != null`) e `'${lembrete.intervaloDias! ~/ 30} meses'` (quando `intervaloDias != null`) — o modelo `LembreteManutencao` só guarda `intervaloDias`; a conversão para meses (`dias ~/ 30`) segue o mesmo padrão já usado em `veiculo_form_screen.dart:54`. Chips usam `TextStyle(fontSize: 11, fontWeight: FontWeight.w600)`.
- **Botão sempre visível**: remove a condição `if (status != StatusLembrete.emDia)` — o `FilledButton.tonalIcon` passa a renderizar para todo lembrete, com label fixo `'Marcar como feito'` (troca de `'Marcar como resolvido'`). Cor continua vindo de `corFundo`/`corTexto` do status (verde quando em dia, laranja/vermelho quando alerta/vencido) — mantém o mesmo `onPressed` (abre `ManutencaoFormScreen` com `lembreteParaResolver`).
- **Remove o link "Editar regra"**: o `GestureDetector` com o texto sublinhado é removido. Editar a regra do lembrete continua possível pela aba (não há tela alternativa hoje) — como não há outra forma de editar no design atual, o toque no próprio card (fora dos botões) passa a abrir `LembreteFormScreen` (mesmo destino que o link removido), envolvendo o `Container` do card em `InkWell`/`onTap`.

### `calculadora_combustivel_screen.dart`

- **Reordena campos**: bloco "Consumo do veículo (km/L)" passa a vir *antes* de "Preço do combustível (R$/L)" (troca de posição dos dois `TextFormField`, sem mudar lógica).
- **Hint persistente**: quando `widget.consumoSugerido != null`, mostra abaixo do campo de consumo `Text('Média registrada do veículo: ${consumoSugerido!.toStringAsFixed(1)} km/L', style: TextStyle(fontSize: 11, color: kAccentColor))`; ao lado do rótulo "CONSUMO DO VEÍCULO (KM/L)" (dentro do `_rotulo`, que passa a aceitar uma ação opcional), um `TextButton` pequeno `'Usar ${consumoSugerido!.toStringAsFixed(1)} km/L'` que faz `_consumoController.text = consumoSugerido!.toStringAsFixed(1)` — útil porque hoje o valor só é preenchido uma vez no `initState`; se o usuário apagar o campo não há como recuperar sem sair da tela.

### `manutencao_form_screen.dart` e `abastecimento_form_screen.dart`

- **Reordena campos** (só `manutencao_form_screen.dart`, `abastecimento_form_screen.dart` não tem equivalente no mockup e mantém sua ordem atual): "Oficina" passa para logo depois do seletor de "Tipo" (antes de "Data realizada"); ordem final: Tipo → (Descrição, se Outro) → Oficina → Km na data → Custo → Data realizada → Observações.
- **Botão fixo com gradiente** (as duas telas): o `FilledButton` de salvar sai de dentro do `ListView` e vira `bottomNavigationBar` do `Scaffold`, dentro de um `Container` com `padding: EdgeInsets.fromLTRB(16, 12, 16, 16)`, `decoration: BoxDecoration(gradient: LinearGradient(colors: [colorScheme.primary.withValues(alpha: 0.9), colorScheme.primary]), borderRadius topo 16)`, contendo o mesmo `FilledButton` (texto branco/`onPrimary`, sem cor de fundo própria — herda do gradiente do container, `style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent)`). Isso extrai um widget compartilhado `BotaoSalvarFixo` (novo arquivo `lib/widgets/botao_salvar_fixo.dart`, recebe `label`, `onPressed`, `carregando`) para não duplicar a decoração entre as duas telas.

## Erros

Nenhuma mudança de tratamento de erro — os `catch (_)` e `SnackBar` existentes continuam iguais.

## Testes

- `test/widgets/veiculo_card_test.dart`: novo caso — renderiza `chevron_right` no trailing.
- `test/widgets/lembrete_tab_test.dart` (novo): card com status "Em dia" também renderiza o botão "Marcar como feito"; card mostra chip "cada X km" quando `intervaloKm` não é nulo; toque no card (fora do botão) navega para `LembreteFormScreen`.
- `test/widgets/botao_salvar_fixo_test.dart` (novo): renderiza o label recebido; `onPressed` é chamado ao tocar; fica desabilitado quando `carregando: true`.
- Sem teste novo para `calculadora_combustivel_screen.dart` e reordenação de campos em `manutencao_form_screen.dart` (mudança de layout/ordem, sem lógica nova testável além do que `abastecimento_form_screen_test.dart`/nenhum teste existente já cobre) — verificação por `flutter analyze` + teste manual no app.
