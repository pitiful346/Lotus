# Sincronizar um novo export do FlutterFlow

## Princípio

Um export é uma atualização de código gerado, não uma substituição cega do
repositório. `packages/`, `docs/`, testes próprios e ficheiros de automação são
propriedade do projeto e devem permanecer.

## Processo recomendado

1. Criar uma branch temporária a partir da branch de integração.
2. Aplicar o novo export nessa branch sem apagar `packages/`, `docs/` e testes
   próprios.
3. Criar um commit contendo apenas o export bruto.
4. Confirmar que a dependência local `lotus_core` continua no `pubspec.yaml`.
5. Comparar as alterações em `lib/custom_code/` e preservar o corpo do código
   entre os marcadores do FlutterFlow.
6. Reaplicar, em commits separados, apenas as correções ainda necessárias ao
   código gerado.
7. Executar:

   ```text
   flutter pub get
   flutter analyze
   flutter test
   ```

8. Integrar a branch apenas quando as três verificações passarem.

## Conflitos

- Preferir a versão do novo export nas zonas geradas.
- Preferir a versão do projeto em `packages/`, `docs/` e testes próprios.
- Em `lib/custom_code/`, preservar o cabeçalho automático do novo export e
  voltar a aplicar apenas o corpo personalizado.
- Nunca resolver conflitos movendo lógica de negócio para uma página gerada.
