# Mapbox na Home

## Configurar o token

A Home lê um token público Mapbox em compile time. O token não é guardado no
repositório e deve começar por `pk.`.

Executar localmente:

```text
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.seu_token_publico
```

Criar builds:

```text
flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=pk.seu_token_publico
flutter build ios --dart-define=MAPBOX_ACCESS_TOKEN=pk.seu_token_publico
```

Em CI, guardar o valor como secret e acrescentar o mesmo `--dart-define` ao
comando de build. Não usar nem incluir no projeto o token secreto de downloads
Mapbox (`sk.`). O token público deve ter apenas os scopes necessários e
restrições adequadas às aplicações Lotus.

## Comportamento

- a Home é ocupada integralmente pelo mapa;
- a câmara começa no Porto (`41.14961, -8.61099`), com zoom `12.5`;
- o estilo é Mapbox Standard com `lightPreset` definido como `night`;
- a instância do mapa é estável durante o lifecycle e o tema é reaplicado ao
  regressar ao foreground;
- os eventos válidos do Firestore são convertidos para o modelo de domínio e
  apresentados como pins personalizados;
- a área inicial é carregada uma vez; depois de mover a câmara, o botão
  `Pesquisar nesta área` inicia explicitamente uma nova pesquisa;
- apenas eventos dentro do viewport são mostrados e os resultados são
  agrupados em clusters até ao zoom `14`;
- tocar num pin apresenta um preview com imagem, nome, data, distância,
  categoria e acesso à página de detalhes;
- o botão `Centrar em mim` pede permissão apenas após interação, obtém a
  localização atual, apresenta o puck do utilizador e anima a câmara;
- quando o token não existe, a aplicação mostra um estado de configuração em
  vez de criar um mapa inválido;
- web e desktop mostram um fallback, porque a versão estável do SDK Mapbox
  usada pelo projeto suporta iOS e Android.

## Configuração nativa

O projeto já cumpre os requisitos usados por esta integração:

- iOS deployment target `14.0`;
- Android `minSdkVersion 24` (mínimo da toolchain Flutter validada);
- aceleração gráfica ativa na `MainActivity`;
- permissões de Internet e localização presentes no Android;
- descrição de acesso à localização presente em `ios/Runner/Info.plist`.

Não é necessário guardar o token em `AndroidManifest.xml`, `Info.plist` ou
ficheiros de configuração locais. A atribuição é feita antes da criação do
`MapWidget` através de `MapboxOptions.setAccessToken`.

## Pesquisa e performance

O widget usa uma chave estável e não reconstrói a plataforma nativa em pausas
da aplicação. O evento `map idle` serve apenas para guardar o viewport atual:
arrastar ou ampliar o mapa não provoca leituras Firestore. A pesquisa tem um
limite rígido de 250 candidatos e substitui os resultados anteriores.

Os pins vivem num único GeoJSON source do estilo Mapbox. Alterar resultados
atualiza esse source uma vez; o clustering e a renderização ficam no SDK nativo,
sem criar uma annotation Flutter por evento. Tocar num cluster aproxima a
câmara; tocar num pin mantém o preview existente.

O schema FlutterFlow atual tem apenas o GeoPoint `coordenadas`. Por isso a query
reduz os candidatos no servidor pela latitude, aplica o limite e só depois
confirma longitude e viewport no caso de uso. Isto já evita carregar toda a
coleção. Para escala metropolitana/nacional, a migração seguinte deve adicionar
um campo `geohash` e consultar os seus intervalos, seguindo a solução oficial de
[geoqueries do Firestore](https://firebase.google.com/docs/firestore/solutions/geoqueries).

A Home verifica silenciosamente uma permissão já concedida, mas abrir o mapa
não apresenta um pedido de localização. O pedido do sistema só é iniciado ao
tocar em `Centrar em mim`. Se o serviço estiver desligado ou a permissão tiver
sido recusada permanentemente, a mensagem permite abrir as definições certas.

A coordenada obtida é convertida para `GeoCoordinates` e as distâncias até aos
eventos são calculadas no `lotus_core`, sem dependência de Mapbox ou Geolocator.
Sem posição válida, o preview indica que a distância está indisponível. O
documento Firestore só é resolvido quando o utilizador escolhe `Ver detalhes`.
