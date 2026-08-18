# Navegação principal e descoberta

## Estrutura

A área autenticada usa uma shell própria em
`lib/custom_code/widgets/lotus_main_shell.dart`. Os separadores são criados só
na primeira visita; depois, um `IndexedStack` mantém o estado e a posição de
scroll ao alternar entre os quatro destinos:

1. **Mapa** — Home Mapbox fullscreen, pesquisa, filtros, localização, pins e
   preview do evento.
2. **Explorar** — descoberta sem mapa: destaque, hoje, fim de semana, perto de
   mim, categorias e trending.
3. **Favoritos** — próximos eventos guardados e eventos passados, com remoção
   direta e tratamento de eventos removidos.
4. **Perfil** — identidade, edição, interesses, cidade, favoritos, definições,
   logout e eliminação de conta.

O FlutterFlow só conhece a página `HomeWidget`; essa página delega a UI à shell
customizada. Assim, um novo export tem um ponto de integração pequeno e
facilmente reaplicável.

## Pesquisa

A pesquisa convencional cobre eventos, locais, categorias e o campo de
organizador/artista. As últimas oito pesquisas ficam apenas no dispositivo e
podem ser apagadas. Sugestões rápidas encaminham para o mesmo motor, incluindo
as frases que já suportam interpretação em filtros estruturados.

## Limites de dados

- Explorar carrega no máximo 80 eventos por atualização.
- Favoritos resolve no máximo 120 referências, em lotes de 30 documentos.
- O mapa continua a usar queries limitadas ao viewport e clustering.

Estes limites evitam transformar a shell num novo ponto de carregamento global.
Uma paginação real pode substituir cada adapter sem alterar os widgets.

## Estados de produto

Os novos separadores reutilizam as primitivas de
`lib/custom_code/product_quality/` para loading, vazio, offline e informação.
Os percursos distinguem ainda localização recusada, evento removido e sessão
ausente. O gate de autenticação continua responsável por sessão expirada.

## Conta e privacidade

A eliminação pede novamente a palavra-passe antes de apagar o utilizador no
Firebase Authentication. A função `onUserDeleted` remove depois os documentos,
subcoleções e imagens associados. Esta função tem de estar publicada no projeto
Firebase para a eliminação de dados ficar completa.
