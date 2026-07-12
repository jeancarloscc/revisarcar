# Prompt para Figma Make — Redesign do RevisaCar

Copie e cole o texto abaixo no Figma Make.

---

Crie o design de um aplicativo mobile (Android/iOS, uso em pé, uma mão) chamado **RevisaCar**, em português do Brasil, para donos de carro e moto controlarem a manutenção do veículo. É um app funcional hoje, construído em Flutter/Material Design 3, mas com visual genérico (lista simples, sem hierarquia visual, sem tema próprio) — quero um redesign completo mantendo todas as telas e fluxos abaixo, com um visual mais moderno, acolhedor e fácil de escanear rapidamente (o usuário típico está na garagem ou na oficina, com pouco tempo).

## Público-alvo

Donos de carro/moto no Brasil, sem perfil técnico, que querem parar de esquecer trocas de óleo, revisões, calibragem de pneus etc. Tom: prático, confiável, sem jargão técnico.

## Telas e fluxos

**1. Login**
Tela simples: nome do app, botão "Entrar com Google". Estado de erro (mensagem de falha no login).

**2. Lista de veículos** (tela inicial após login)
- AppBar com ícone de configurações.
- Lista de cartões, um por veículo: ícone (carro ou moto), nome do veículo, modelo + km atual, ação de excluir.
- Estado vazio: "Nenhum veículo cadastrado, toque em + para adicionar o primeiro."
- Botão flutuante (+) para cadastrar veículo.

**3. Detalhe do veículo**
- AppBar com nome do veículo + ícone de editar.
- Cabeçalho: ícone (carro/moto) + modelo, ano, placa, km atual.
- Navegação inferior fixa com 3 itens, cada um só com ícone quando não selecionado e ícone+nome quando selecionado: **Manutenções** (ícone de ferramenta/chave), **Abastecimentos** (ícone de bomba de combustível), **Lembretes** (ícone de sino/notificação).

**3a. Aba Manutenções**
- Bloco "Próximas manutenções" no topo: uma linha por tipo de manutenção com lembrete ativo, mostrando tipo + km e/ou data prevista (ex: "Troca de óleo: 50.000 km ou 15/03/2027"). Hoje é só texto simples — quero algo mais escaneável visualmente (ex: chips/cards compactos, com destaque para o que está mais próximo de vencer).
- Abaixo, histórico de manutenções (mais recente primeiro): tipo, oficina, km na data, custo. Deslizar para excluir (com confirmação).
- Botão flutuante (+) para nova manutenção.
- Toque em um registro abre o formulário em modo edição.

**3b. Aba Abastecimentos**
Mesmo padrão de lista: data, litros, valor, km — histórico de abastecimentos, com botão + para novo registro.

**3c. Aba Lembretes**
- Lista de regras de lembrete (uma por tipo de manutenção configurado), cada uma com um status visual: **Em dia** (verde), **Alerta antecipado** (laranja), **Vencido** (vermelho) — hoje é só uma bolinha colorida + texto, quero algo com mais impacto visual (ícone de status, ou um cartão com barra/borda colorida).
- Ação "Marcar como resolvido" quando o lembrete está em alerta/vencido, que abre o formulário de nova manutenção já preenchido com o tipo.
- Botão + para criar lembrete manualmente.

**4. Formulário de manutenção**
Campos: tipo (dropdown, com opção "Outro" que libera um campo de descrição livre), data realizada (seletor de data), km na data, custo (R$), oficina, observações. Botão "Salvar".

**5. Formulário de abastecimento**
Campos similares: data, litros, valor, km, tipo de combustível.

**6. Formulário de lembrete**
Campos: tipo de manutenção, intervalo em km, intervalo em dias, antecedência (km/dias) para avisar antes de vencer, repetir notificação a cada X dias, ativo/inativo (switch).

**7. Formulário de veículo (criar/editar)**
- Campos básicos: nome, modelo, ano, placa, km atual, tipo (carro/moto).
- Seção "Intervalos de manutenção": uma linha por tipo de manutenção (revisão, troca de óleo, troca de filtro, pneus/rodízio, bateria, palhetas, ar-condicionado, alinhamento/balanceamento — 8 tipos), cada uma com dois campos numéricos opcionais (km e meses) que definem de quanto em quanto tempo o app deve lembrar automaticamente daquele tipo de manutenção nesse veículo específico. **Esta é a tela mais densa e mais precisando de redesign** — hoje são 8 pares de campos numéricos genéricos empilhados, sem ícone ou agrupamento visual. Pense em uma solução mais elegante: cards por tipo com ícone reconhecível, campos recolhíveis/expansíveis, ou um layout em grade mais compacto.

**8. Configurações**
Tela simples: opção "Sair da conta".

## Direção visual desejada

- Ainda dentro do espírito Material Design 3 (é um app Flutter), mas com uma paleta de cor própria e intencional — não só uma cor semente genérica. Sugira paleta (cor primária, secundária, cores de status de lembrete) e tipografia.
- Deve funcionar bem em tema claro e escuro.
- Cards com leve elevação/sombra para separar conteúdo, em vez de listas "cruas".
- Ícone por tipo de manutenção (óleo, filtro, pneu, bateria, palheta, ar-condicionado, alinhamento) usado de forma consistente nas telas de manutenção, lembrete e configuração de intervalos — ajuda a escanear rápido.
- Prioridade de legibilidade em telas de lista densas (histórico de manutenções/abastecimentos, lembretes, configuração de intervalos).
