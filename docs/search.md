# Pesquisa convencional

## Comportamento atual

A página `/search` mantém a rota gerada pelo FlutterFlow, mas delega a interface
e a lógica ao widget próprio `LotusEventSearch`. A pesquisa:

- ignora maiúsculas, minúsculas e acentos;
- aceita vários termos e exige que todos correspondam;
- apresenta resultados separados em Eventos, Locais, Artistas e Categorias;
- abre diretamente os detalhes de um evento;
- mostra os eventos relacionados ao escolher um local, artista ou categoria;
- espera 350 ms após a escrita antes de pesquisar.

## Acesso a dados

Esta primeira versão usa um corpus convencional e limitado aos próximos 200
eventos. O corpus é carregado apenas na primeira pesquisa de cada abertura da
página e reutilizado nas pesquisas seguintes. Os organizadores referenciados
são obtidos em lotes de até 30 documentos, evitando uma leitura individual em
série por evento.

O contrato `EventSearchRepository` separa a interface da origem dos dados. Se o
volume ultrapassar este limite, a implementação Firestore pode ser substituída
por um índice dedicado, como Algolia, Typesense ou Elasticsearch, sem alterar a
página nem o modelo dos resultados.
