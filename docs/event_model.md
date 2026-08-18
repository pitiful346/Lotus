# Modelo de dados dos eventos

`lotus_core` contém o modelo canónico `Event`, independente de Flutter,
Firebase e Mapbox. O record `EventsRecord` do export continua disponível como
legado, mas não deve ser usado como modelo de negócio em código novo.

## Estrutura

- identidade: `id`;
- conteúdo: `title`, `description` e `imageUri`;
- classificação: categorias dinâmicas com `id` estável e nome apresentado;
- localização: nome, venue, morada, cidade, região, país e latitude/longitude;
- horário: início, fim opcional e identificador de timezone;
- preço: intervalo em unidades mínimas da moeda e código ISO 4217;
- organizador: identidade, nome, website e imagem;
- links tipados: tickets, website, streaming, social e outros;
- filtros: formato, estado, disponibilidade de tickets, tags, idiomas,
  acessibilidade, idade mínima e destaque;
- auditoria: datas opcionais de criação, atualização e publicação.

Datas são normalizadas para UTC. `timeZoneId` preserva a zona usada para
apresentação. Preços são inteiros em unidades mínimas — por exemplo, `1250`
representa `12,50 EUR` — para evitar erros de arredondamento.

## Compatibilidade com o schema atual

| Firestore legado | Domínio |
| --- | --- |
| `name` | `title` |
| `description` | `description` |
| `categoria` | `categories` |
| `location`, `venue_name` | `location` |
| `coordenadas` | `location.coordinates` |
| `start_date`, `end_date` | `startsAt`, `endsAt` |
| `image` | `imageUri` |
| `is_free`, `price_min` | `price` |
| `organizer_id` | `organizer` |
| `ticket_url`, `ticket_status` | `links`, `ticketAvailability` |
| `is_boosted` | `isFeatured` |
| `is_archived` | `status: archived` |

A conversão deve ser implementada num adapter da infraestrutura ou da ponte
FlutterFlow. O domínio não importa `EventsRecord`, `DocumentReference`,
`LatLng` nem `GeoPoint`.
