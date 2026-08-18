# Models

Entidades, value objects e tipos de domínio imutáveis. Não importar Flutter,
Firebase nem records gerados pelo FlutterFlow.

O modelo `Event` é a representação canónica de um evento. Os adapters na
fronteira da aplicação convertem `EventsRecord` e outros formatos externos para
este modelo; nomes de campos Firestore não entram nesta camada.
