# Backend Firebase

## Decisão

O Lotus usa uma única plataforma de backend:

- **Firebase Authentication** para identidade;
- **Cloud Firestore** para eventos, utilizadores, favoritos e organizadores;
- **Cloud Storage** para imagens;
- **Cloud Functions** apenas para operações que exigem privilégios de servidor;
- **App Check** como camada de proteção a ativar depois de registar as apps e
  observar métricas, sem bloquear já os clientes existentes.

Esta escolha mantém a configuração nativa e os records do export FlutterFlow
que já funcionam. Supabase ou um backend próprio introduziriam uma segunda
identidade, migração de dados e dois SDKs sem resolver um requisito atual.

O projeto Firebase configurado nas apps é `lotus-lxr3lu`. Este identificador e
as opções Firebase do cliente não são segredos. Credenciais de conta de serviço,
tokens CI e chaves privadas nunca entram no repositório.

## Modelo de dados

```text
events/{eventId}                         catálogo público
organizers/{uid}                         perfil público do organizador
users/{uid}                              conta privada do utilizador
users/{uid}/favorites/{eventId}          favoritos privados e escaláveis
users/{uid}/preferences/personalization  interesses privados
users/{uid}/interactions/{eventId}        histórico agregado privado
```

### `events`

Mantém os nomes de campos do export FlutterFlow durante a migração. Novas
escritas exigem título, data de início, referência a `organizers/{uid}` e os
campos de moderação. A leitura é pública porque o documento só pode conter
informação do catálogo. `is_archived` controla visibilidade na aplicação, não
deve guardar informação confidencial.

Organizadores autenticados podem criar e editar apenas os próprios eventos.
Não podem trocar o proprietário, destacar, arquivar, eliminar ou alterar o
contador de cliques. Essas operações pertencem a administradores.

### `users`

É privado para o próprio utilizador e administradores. Contém email, telefone,
nome, imagem e dados do export necessários à conta. Não contém papéis nem dados
públicos de organizadores, evitando que uma leitura pública exponha email ou
telefone.

O array `favoritos` é mantido temporariamente porque vários widgets gerados
ainda o usam. Código novo usa a subcoleção `favorites`; a implementação atual
faz as duas escritas na mesma transação. Depois de migrar os últimos widgets e
os documentos existentes, o array pode ser removido.

Interesses e interações vivem em subcoleções privadas. Uma interação agrega
contadores por evento, evitando uma escrita histórica ilimitada por cada toque.
O detalhe completo da estratégia está em `docs/personalization.md`.

### `organizers`

É um perfil público separado, cujo ID e `owner_id` correspondem ao UID do
responsável. O cliente pode atualizar conteúdo público, mas não pode alterar
`is_verified`. Eventos novos referenciam esta coleção em `organizer_id`.

Referências antigas de eventos para `users/{uid}` continuam legíveis apenas
para o próprio utilizador ou um administrador. Os adapters aceitam ambos os
caminhos durante a migração, sem tornar documentos privados públicos.

## Papéis e autenticação

As permissões elevadas são custom claims emitidas exclusivamente num ambiente
de servidor com Admin SDK:

- `admin: true` — moderação, eliminação e gestão global;
- `organizer: true` — manutenção do perfil e eventos do próprio organizador.

Nunca se decide autorização através de um campo que o utilizador possa editar.
Depois de atribuir ou retirar uma claim, a sessão deve renovar o ID token.

No Firebase Console devem ser ativados apenas os providers usados pelo produto.
A base atual suporta Email/Password, Google e Apple. Anonymous, Phone, GitHub e
JWT devem permanecer desativados até existir um fluxo, configuração e política
de conta explícitos para cada um.

## Storage

Os caminhos suportados são:

```text
users/{uid}/uploads/{ficheiro}
organizers/{uid}/{ficheiro}
events/{organizerUid}/{eventId}/{ficheiro}
```

Uploads aceitam apenas JPEG, PNG, WebP ou GIF. Imagens de perfil têm limite de
5 MiB; imagens públicas têm limite de 10 MiB. A pasta de utilizador mantém o
caminho atualmente produzido pelo FlutterFlow. Media pública inclui o UID do
organizador no caminho, permitindo validar propriedade sem confiar no nome do
ficheiro.

## Lifecycle de conta

`onUserDeleted` elimina recursivamente o documento do utilizador e os seus
favoritos, o perfil de organizador e os prefixos de Storage associados. Uma
falha faz a Function falhar para ficar visível nos logs e permitir retry, em
vez de deixar uma eliminação parcial silenciosa.

As Functions usam o runtime Node.js 22 e imports modulares do Admin SDK. As
versões ficam fixas e o `package-lock.json` deve acompanhar o código para tornar
o deploy reproduzível.

## Ativação segura

Para o tooling atual, usar Node.js 22.12 ou superior nas Functions, JDK 21 no
Emulator Suite e a versão corrente do Firebase CLI. O build Android da app
continua a usar JDK 17.

Executar a partir de `firebase/`, usando uma conta autorizada:

```text
firebase emulators:start --only firestore,storage,auth,functions
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions
```

Antes do deploy:

1. criar backup/export do Firestore;
2. confirmar que cada documento `users/{uid}` tem `uid` e `created_time`;
3. criar `organizers/{uid}` e migrar gradualmente `events.organizer_id`;
4. testar criação de conta, edição de perfil, favoritos e leitura pública;
5. atribuir claims apenas por ferramenta administrativa auditada;
6. registar iOS, Android e web no App Check, observar métricas e só depois
   ativar enforcement serviço a serviço.

As regras do repositório não ficam ativas até serem publicadas no projeto
Firebase. O deploy deve ser separado do deploy da aplicação e ter rollback
preparado.
