# Pesquisa em linguagem natural

## Baseline atual

A pesquisa aceita frases como:

```text
quero techno amanhã à noite no Porto
eventos gratuitos hoje de manhã
música este fim de semana até 20 euros
```

`ParseNaturalEventQuery` converte o texto, no dispositivo, num
`NaturalEventQuery` estruturado e inspecionável:

- intervalo de datas;
- período do dia: madrugada, manhã, tarde ou noite;
- local;
- categorias e termos específicos;
- apenas eventos gratuitos;
- preço máximo.

A interface mostra chips com a interpretação antes dos resultados. A pesquisa
convencional por evento, local, artista e categoria continua ativa quando não
existem restrições naturais suficientes.

## Execução

`SearchEventsNaturally` aplica todos os filtros ao corpus limitado dos próximos
200 eventos e ordena os resultados por data. A frase de exemplo transforma-se
aproximadamente em:

```text
dateStart: amanhã 00:00
dateEndExclusive: dia seguinte 00:00
dayPeriod: night
locationTerms: [porto]
categoryIds: [musica]
keywordTokens: [techno]
```

Esta versão reconhece português, localidades iniciais do Porto e algumas
cidades portuguesas, sinónimos das categorias principais, datas relativas e
preços inteiros em euros. Não tenta fingir compreensão quando não reconhece uma
estrutura: nesse caso usa a pesquisa convencional.

## Privacidade e limites

O texto não é enviado para Firebase, OpenAI ou outro serviço e não é guardado no
histórico de personalização. O parser é baseado em regras, logo é previsível e
testável, mas não compreende ainda linguagem arbitrária, erros muito distantes
das palavras conhecidas ou relações semânticas complexas.

## Evolução semântica

`NaturalEventQueryInterpreter` é a fronteira substituível. Uma fase futura pode
usar um modelo para produzir o mesmo `NaturalEventQuery`, mantendo validação e
fallback local.

Embeddings devem ser introduzidos apenas quando o volume justificar:

1. gerar embeddings de eventos no backend quando o catálogo muda;
2. gerar o embedding da consulta num endpoint autenticado, nunca com uma chave
   secreta dentro da aplicação;
3. procurar candidatos num índice vetorial limitado por data, cidade e estado;
4. aplicar novamente permissões e filtros estruturados;
5. devolver razões simples e manter fallback para pesquisa convencional.

O índice semântico deve guardar apenas conteúdo público dos eventos. Consultas
do utilizador só devem ser conservadas com uma política explícita de privacidade
e retenção.
