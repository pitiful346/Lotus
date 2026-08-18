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

## Performance

O widget usa uma chave estável, não subscreve eventos contínuos de câmara ou de
renderização e não reconstrói a plataforma nativa em pausas da aplicação. Para
eventos futuros em volume, preferir sources/layers do estilo a uma annotation
Flutter por evento.
