# Arquitetura do Lotus

## Objetivo

O Lotus continua a poder receber novos exports do FlutterFlow sem obrigar o
código de negócio a viver dentro de widgets gerados. A migração é incremental:
o legado mantém-se funcional e cada funcionalidade nova começa já na estrutura
nova.

## Zonas de propriedade

### Gerado pelo FlutterFlow

As seguintes áreas são tratadas como código de fornecedor e podem ser
reescritas num novo export:

- `lib/main.dart`, `lib/app_state.dart` e `lib/index.dart`;
- `lib/auth/` e `lib/backend/`;
- `lib/components/`, `lib/pages/` e `lib/inativo/`;
- `lib/flutter_flow/`;
- configuração nativa em `android/`, `ios/` e `web/`.

Não se acrescenta lógica de negócio nova nestas áreas. Correções inevitáveis
ao código gerado devem ficar em commits pequenos e identificáveis, para poderem
ser reaplicadas depois de um export.

### Ponte com o FlutterFlow

`lib/custom_code/` é a fronteira de integração suportada pelo FlutterFlow.
Widgets, actions e functions aqui presentes devem ser finos:

1. recebem e convertem valores do FlutterFlow;
2. chamam um caso de uso do `lotus_core`;
3. transformam o resultado em estado ou UI.

Não guardam regras de negócio, queries Firebase complexas nem modelos próprios.
Os cabeçalhos de imports automáticos e os marcadores do FlutterFlow devem ser
preservados.

### Código nosso

O código que deve sobreviver aos exports vive em `packages/lotus_core/`:

```text
packages/lotus_core/lib/src/
├── domain/
│   ├── models/          modelos e value objects sem Flutter/Firebase
│   └── repositories/    contratos de acesso a dados
├── application/
│   └── use_cases/       regras e orquestração da aplicação
└── infrastructure/
    ├── repositories/    implementação dos contratos
    └── services/        Firebase, HTTP, localização e armazenamento
```

A UI continua no FlutterFlow ou em `lib/custom_code/widgets/`. Se a quantidade
de UI própria crescer significativamente, poderá ser extraída mais tarde para
um pacote `lotus_ui`; não é necessário criar esse custo agora.

## Direção das dependências

```text
FlutterFlow UI -> custom_code bridge -> application -> domain
                                      -> infrastructure -> APIs/SDKs
```

Regras:

- `domain` não depende de Flutter, Firebase, HTTP ou do projeto gerado;
- `application` depende de `domain`, nunca de widgets ou records do FlutterFlow;
- `infrastructure` implementa os contratos definidos em `domain`;
- a ponte em `custom_code` faz composição e conversão de tipos;
- modelos como `EventsRecord` não atravessam para `domain`; são convertidos na
  fronteira;
- páginas não chamam serviços diretamente. Chamam casos de uso através da
  ponte.

## Como desenvolver uma funcionalidade nova

1. Definir os modelos e contratos em `domain`.
2. Implementar a regra em `application/use_cases`.
3. Criar a integração externa em `infrastructure`.
4. Expor apenas a operação necessária através de um widget/action/function em
   `lib/custom_code/`.
5. Ligar essa ponte à página FlutterFlow.
6. Criar testes do caso de uso sem Flutter e um teste pequeno da ponte.

Não é necessário migrar todo o legado. Um fluxo antigo só é movido quando for
alterado por uma necessidade real.

## Guardrails

- `test/architecture_test.dart` impede dependências de Flutter/Firebase nas
  camadas puras e impede o pacote próprio de importar o projeto gerado;
- `flutter analyze` e `flutter test` são obrigatórios antes de cada commit;
- `pubspec.lock` permanece versionado;
- novos exports seguem `docs/flutterflow_sync.md`.
