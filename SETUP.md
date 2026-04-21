# Setup recomendado

## 1) Supabase

1. Crea proyecto en Supabase.
2. Ejecuta la migración SQL:
   - `supabase/migrations/20260420_initial_family_app.sql`
3. Crea bucket privado:
   - `family-files`
4. Configura Auth:
   - Email/password enabled
   - Confirm email según prefieras
5. Configura URL redirect si usas magic links más adelante.

## 2) Firebase / FCM

1. Crea proyecto Firebase.
2. Añade Android e iOS.
3. Ejecuta:
   ```bash
   flutterfire configure
   ```
4. Añade `google-services.json` en Android y `GoogleService-Info.plist` en iOS.
5. Configura APNs para iOS según la guía de Firebase.

## 3) Edge function push

La función `push-dispatch` usa HTTP v1 de FCM.
Debes guardar estos secrets en Supabase Functions:

- `FCM_PROJECT_ID`
- `FCM_CLIENT_EMAIL`
- `FCM_PRIVATE_KEY`

y desplegar:

```bash
supabase functions deploy push-dispatch
```

## 4) Flutter

Edita `lib/core/env.dart` con:

- Supabase URL
- Supabase anon key

## 5) Realtime

En Supabase, activa Realtime para:
- `chat_messages`
- `shopping_items`
- `tasks`
- `events`
- `meal_entries`
- `notifications`
