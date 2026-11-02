# pratica5

Pernas de Corredor: Aula 10, Consumo de API REST (Atividade Prática 5).
Uma tela só, que busca na wger os exercícios de pernas e mostra o nome, o músculo principal e o equipamento de cada um.

## Justificativa da API

Escolhi a API da wger (`https://wger.de/api/v2/exerciseinfo/?category=9`) porque cada exercício traz o nome em vários idiomas (`translations`), os músculos (`muscles`) e os equipamentos (`equipment`) em listas separadas, e a lista inteira vem embrulhada num objeto (`results`).
Não pede chave nem cadastro, então não há chave para esconder.

## Onde está cada parte

- `lib/exercicio.dart`: o modelo. É o único lugar que conhece os nomes da API, e todo campo é lido com `as Tipo?` e `??`.
- `lib/main.dart`: a `ExerciciosApi` (`http.get`, `timeout`, conferência do `statusCode`, `jsonDecode`), a `ExerciciosStore` (o `enum Estado`, a busca no construtor e os dois `notifyListeners`) e a tela com o `switch` dos quatro estados.

## Como testar o erro

1. Com internet, rode `flutter run -d chrome` e espere a lista aparecer.
2. Desligue a internet **sem fechar nem recarregar a página**.
3. Toque no botão de recarregar da barra. Aparece a mensagem de erro e o botão "Tentar de novo".
4. Religue a internet e toque em "Tentar de novo". A lista volta.

No Chrome, não reabra o app sem internet: o Flutter Web baixa o próprio motor de desenho (CanvasKit) e as fontes do `gstatic.com` a cada carregamento da página, e sem rede a tela fica branca antes de o app rodar. No emulador Android isso não acontece; lá dá para ativar o modo avião e reabrir o app.

## Declaração de uso de IA

Usei IA (Claude) para apoiar a implementação seguindo o roteiro da Aula 10.
