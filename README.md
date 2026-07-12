# revisacar

App Flutter para controle de manutenção veicular (carros e motos): histórico de manutenções, lembretes, abastecimentos e checklist por veículo, com dados sincronizados na nuvem via Firebase. Interface em português (Brasil).

## Stack

- **Flutter** (SDK `^3.12.2`) — Android e iOS
- **Gerenciamento de estado:** `provider`
- **Backend:** Firebase (`firebase_core`, `firebase_auth` + `google_sign_in`, `cloud_firestore`)
- `shared_preferences`, `google_fonts`, `flutter_localizations`

## Como rodar

1. Instale as dependências:
   ```
   flutter pub get
   ```
2. Configure o Firebase do projeto (arquivos `google-services.json` / `GoogleService-Info.plist` já referenciados em `firebase.json`; use `flutterfire configure` se precisar regenerar).
3. Rode o app em um dispositivo/emulador Android ou iOS:
   ```
   flutter run
   ```

## Testes

```
flutter test
```
