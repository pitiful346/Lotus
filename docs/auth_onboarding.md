# Autenticação e onboarding

## Autenticação

Firebase Authentication continua a ser a fonte de verdade da sessão. A nova
fronteira vive em `lib/custom_code/auth/` e oferece:

- login e registo por email e palavra-passe;
- criação do documento `users/{uid}` depois do registo;
- recuperação de palavra-passe por email;
- logout com confirmação nas Definições;
- persistência local explícita no browser e persistência nativa do Firebase em
  Android/iOS;
- mensagens de erro curtas em português, sem expor detalhes internos.

As rotas de produto são privadas. Um acesso sem sessão é enviado para o novo
ecrã de autenticação e regressa ao destino original depois do login. Os ecrãs
antigos exportados pelo FlutterFlow permanecem no repositório, mas já não são a
entrada principal.

Login social não faz parte desta baseline. O contrato `LotusAuthService`
permite acrescentar Google ou Apple mais tarde sem alterar a UI nem o router.

## Onboarding

Depois do primeiro login, `LotusOnboardingGate` apresenta quatro passos:

1. apresentação curta do Lotus;
2. pedido opcional de localização, com tratamento de recusa;
3. escolha de interesses/categorias;
4. escolha da cidade inicial.

O utilizador pode saltar em qualquer passo. Saltar não apaga interesses que já
existam. A conclusão fica em
`users/{uid}/preferences/onboarding`; os interesses usam o documento existente
`users/{uid}/preferences/personalization`. Uma chave local por utilizador
permite abrir rapidamente a app quando a conclusão já foi confirmada.

A cidade selecionada define a câmara inicial do Mapbox. Porto é o fallback para
contas antigas ou valores desconhecidos.

## Backend e ativação

As regras em `firebase/firestore.rules` validam o documento de onboarding e
limitam a leitura/escrita ao próprio utilizador. Estas regras têm de ser
publicadas no projeto Firebase antes de testar a conclusão contra o backend
real. Esta tarefa altera apenas o repositório; não executa deploy.

## Verificação manual

1. Criar uma conta e confirmar que a sessão sobrevive ao reinício da app.
2. Recusar localização e concluir o onboarding normalmente.
3. Repetir com localização autorizada e uma cidade diferente do Porto.
4. Terminar sessão nas Definições e voltar a entrar.
5. Pedir recuperação de palavra-passe para uma conta válida.
