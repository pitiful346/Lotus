# Página de evento

A rota FlutterFlow `EventDetails` continua a receber um `EventsRecord`, mas a
UI nova vive em `lib/custom_code/widgets/event_details_content.dart`. A página
gerada limita-se a observar os documentos Firestore, converter os dados para o
modelo `Event` e ligar as ações externas.

## Conteúdo

- imagem, nome, categorias, descrição e horário real do evento;
- localização e acesso a direções quando existem coordenadas;
- preço e disponibilidade dos bilhetes;
- nome e imagem do organizador quando `organizer_id` aponta para um perfil
  público em `organizers` ou para um utilizador legado acessível;
- partilha através da interface nativa do sistema;
- favorito persistido na subcoleção `favorites`, com sincronização temporária
  do array legado `favoritos` para os widgets FlutterFlow ainda não migrados;
- compra ou reserva através de `ticket_url`, quando disponível.

Eventos gratuitos apresentam `Reservar`; eventos pagos apresentam
`Comprar bilhete`. Estados esgotado ou indisponível mantêm a informação visível,
mas desativam o acesso à bilheteira. URLs inválidos e campos ausentes nunca
criam ações vazias.

## Limites do schema legado

O schema atual não contém website próprio do organizador, moeda por evento,
preço máximo nem um URL canónico interno para partilha. A página usa EUR para o
campo legado `price_min` e partilha o link de bilhetes quando este existe. Estes
limites ficam representados no modelo de domínio para futura evolução do
Firestore sem voltar a redesenhar a UI.
