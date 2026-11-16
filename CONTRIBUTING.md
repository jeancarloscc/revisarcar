# Como contribuir

Obrigado pelo interesse em contribuir com o RevisarCar! Correções, melhorias e sugestões são bem-vindas.

## Antes de começar

- Para mudanças grandes (uma funcionalidade nova, por exemplo), abra uma issue antes para conversarmos sobre a ideia. Assim ninguém perde tempo com algo que não vai entrar.
- Para correções pequenas (bug, texto, erro de digitação), pode abrir o pull request direto.

## Passo a passo

1. Faça um fork do repositório e crie uma branch a partir da `main`.
2. Faça as mudanças.
3. Rode a análise e os testes, que precisam passar:
   ```
   flutter analyze
   flutter test
   ```
4. Abra um pull request explicando o que mudou e por quê.

Todo pull request é revisado antes de entrar. Posso pedir ajustes ou, em alguns casos, não aceitar a mudança.

## Firebase e login

Os testes não precisam do Firebase e rodam com `flutter test`.

Para rodar o app com login, você vai precisar de um projeto Firebase próprio, porque o login com Google só funciona com as chaves cadastradas no projeto original. Configure com `flutterfire configure`, mas **não inclua no pull request** os arquivos `android/app/google-services.json`, `lib/firebase_options.dart` e `firebase.json` gerados para o seu projeto.

## Padrão de commits

As mensagens seguem o padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/), em português:

```
tipo(escopo): descrição curta no presente
```

Tipos mais usados: `feat` (funcionalidade nova), `fix` (correção), `refactor`, `test`, `docs`, `chore`.

Exemplos:

```
feat(checklist): adiciona aba de checklist do veículo
fix(auth): corrige o login com Google no build release
```

## Licença

Ao enviar uma contribuição, você concorda que ela será distribuída sob a mesma licença do projeto, a [GNU GPL v3.0](LICENSE).
