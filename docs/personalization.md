# Favoritos e personalização

## Experiência

A rota `/saved` é agora o centro pessoal do utilizador e contém:

- **Guardados** — eventos persistidos na subcoleção canónica `favorites`;
- **Para ti** — recomendações básicas com uma razão visível;
- **Atividade** — resumo cronológico das interações recentes;
- **Interesses** — seleção editável de categorias usadas nas recomendações.

É necessário iniciar sessão. A personalização é privada e nunca altera o
catálogo público de eventos.

## Dados

```text
users/{uid}/favorites/{eventId}
users/{uid}/preferences/personalization
users/{uid}/interactions/{eventId}
```

Cada documento de interação agrega o histórico relativo a um evento. Guarda o
primeiro e último instante, última ação, categorias e contadores de visualização,
favorito, partilha, direções e bilheteira. Esta estrutura cresce por eventos
distintos, não por cada toque, e a interface lê no máximo os 100 mais recentes.

As regras Firestore garantem que só o próprio utilizador pode ler ou escrever
estas coleções. Uma atualização de interação apenas pode aumentar a soma dos
contadores em uma unidade e não pode trocar o evento nem o primeiro instante.

## Recomendações básicas

`RecommendEvents` vive no `lotus_core` e não depende de Firebase ou Flutter. A
pontuação é transparente:

1. categorias escolhidas explicitamente têm o maior peso;
2. bilheteira, favoritos, partilhas, direções e visualizações criam afinidade,
   por esta ordem aproximada;
3. sinais recentes pesam mais do que sinais antigos;
4. eventos já guardados ou que começaram no passado são excluídos;
5. sem sinais, são apresentados próximos eventos por data, com um pequeno
   impulso para destaques.

O corpus continua limitado aos próximos 200 eventos. Esta é uma baseline
determinística e testável; não é machine learning. Um futuro serviço remoto pode
implementar outra estratégia sem alterar os modelos ou a interface.

## Privacidade

O histórico serve apenas para a experiência do próprio utilizador. Não inclui
localização contínua, pesquisas livres nem dados do dispositivo. Ao eliminar a
conta, a Function de lifecycle elimina recursivamente preferências, favoritos e
interações. App Check deve ser ativado antes de escalar o tráfego de produção.
