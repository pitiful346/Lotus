# Qualidade de produto

Esta baseline torna previsíveis os estados transitórios e as falhas da Home,
pesquisa, detalhes, favoritos e notificações. As primitivas partilhadas vivem
em `lib/custom_code/product_quality/` para sobreviverem a novos exports do
FlutterFlow sem levar regras de negócio para a UI.

## Estados de interface

| Situação | Comportamento |
| --- | --- |
| Carregamento inicial | Skeletons estáveis, sem saltos de layout e com um único anúncio para leitores de ecrã. |
| Sem resultados | Estado vazio explícito, distinto de uma falha de rede. |
| Erro recuperável | Mensagem curta, ação para tentar novamente e anúncio como live region. |
| Sem ligação | Estado offline próprio; dados já apresentados são preservados sempre que possível. |
| Atualização | O conteúdo anterior mantém-se visível em vez de regressar a um ecrã vazio. |

`LotusStateView`, `LotusSkeletonList` e `LotusAnimatedSwap` são os componentes
base. Novos fluxos devem reutilizá-los antes de criarem variantes locais.

## Cache e offline parcial

- Firestore usa persistência local explícita em Android/iOS, com limite de
  50 MiB. O browser não ativa persistência nesta baseline.
- Imagens remotas usam `CachedNetworkImage`, placeholder local e dimensões de
  memória limitadas quando aplicável.
- O mapa conserva eventos previamente carregados quando uma atualização
  falha. Pesquisa, favoritos, detalhes e notificações conseguem mostrar dados
  que o Firestore já tenha em cache.
- Abrir links externos, comprar bilhetes, partilhar para serviços externos e
  obter conteúdo nunca visitado continuam a exigir rede.

Isto é offline parcial, não sincronização offline completa. Não se deve indicar
ao utilizador que uma operação remota ficou concluída até o backend a aceitar.

## Movimento e feedback tátil

- Mudanças relevantes usam cross-fade curto; skeletons usam um pulso discreto.
- `MediaQuery.disableAnimations` reduz as transições a zero e desliga o pulso.
- Haptics são reservados para seleção intencional, sucesso confirmado e erros
  importantes. Não são emitidos durante scroll, loading ou atualizações
  automáticas.

## Acessibilidade

- Alvos interativos novos têm pelo menos 48 × 48 pontos lógicos.
- Erros, estado offline e loading expõem labels semânticas sem duplicar o texto.
- Resultados de pesquisa, cards de eventos, mapa e toggles têm nomes e estados
  compreensíveis fora do contexto visual.
- Títulos principais são headers semânticos e imagens informativas têm labels.
- Animações respeitam a preferência do sistema por movimento reduzido.

## Checklist antes de publicar

1. Correr `flutter analyze` e `flutter test`.
2. Testar loading, vazio, erro e retry com rede lenta e modo avião.
3. Validar VoiceOver em iOS e TalkBack em Android nas jornadas principais.
4. Verificar texto ampliado, contraste, foco e alvos táteis num dispositivo.
5. Confirmar que dados antigos continuam utilizáveis após reiniciar sem rede.
6. Confirmar que nenhuma falha mostra dados antigos como se fossem recentes.
