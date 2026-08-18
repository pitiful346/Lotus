# Notificações

## Âmbito desta baseline

O Lotus usa Firebase Cloud Messaging (FCM), coerente com o backend já adotado.
As preferências estão desligadas por defeito e são independentes:

- alterações de data, local ou estado de eventos favoritos;
- um lembrete cerca de 24 horas antes de um evento favorito;
- um único resumo semanal de recomendações.

O ecrã de definições pede autorização ao sistema apenas depois de a pessoa
ativar uma destas opções. A app guarda um token por instalação autenticada,
atualiza-o quando o FCM o renova e elimina o registo quando todas as opções são
desligadas. Uma mensagem recebida com a app aberta aparece como aviso interno;
um toque numa notificação de evento abre os respetivos detalhes.

## Proteções contra spam

As Cloud Functions aplicam as regras, mesmo que um cliente seja alterado:

- máximo de 3 notificações por utilizador e dia;
- silêncio entre as 22:00 e as 08:00, em `Europe/Lisbon`;
- chave de deduplicação por utilizador, tipo, evento e versão/data;
- recomendações agrupadas num resumo semanal;
- remoção de tokens inválidos e de instalações sem atualização há 35 dias;
- preferências confirmadas novamente imediatamente antes do envio.

Mensagens criadas durante o período de silêncio ficam numa fila e são
entregues depois das 08:00, sujeitas ao limite diário. Não se envia uma
notificação por cada visualização ou interação.

## Processamento no servidor

As Functions preparadas são:

- `onFavoriteEventChanged`: reage a mudanças relevantes num evento;
- `queueUpcomingFavoriteEvents`: procura eventos favoritos que começam dentro
  de aproximadamente 24 horas;
- `queueWeeklyRecommendations`: cria o resumo semanal para quem o pediu;
- `dispatchPendingNotifications`: entrega a fila a cada 15 minutos.

As Functions e os índices são apenas código neste repositório. Não ficam
ativos até serem publicados no Firebase. Os agendamentos usam Cloud Scheduler
e, por isso, exigem faturação ativa no projeto.

## Ativação iOS e Android

Antes de testar em dispositivos reais:

1. no Firebase Console, carregar uma chave de autenticação APNs para a app iOS;
2. no Xcode, confirmar as capacidades **Push Notifications** e **Background
   Modes** (`Background fetch` e `Remote notifications`);
3. confirmar que o bundle ID e o application ID são os definitivos antes de
   gerar novamente os ficheiros Firebase;
4. publicar regras, índices e Functions numa janela controlada;
5. testar consentimento, recusa, renovação de token, primeiro plano, background
   e app terminada num iPhone e num Android físicos.

O projeto já inclui `POST_NOTIFICATIONS` no Android e os entitlements/background
modes necessários no iOS. A chave APNs é configuração externa e nunca deve ser
incluída no repositório.
