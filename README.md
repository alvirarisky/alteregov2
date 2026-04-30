# alterego_app

A new Flutter project.

## Firestore chat data (AlterEgo)

### Collection path used by the app

Chat history disimpan per-user dan per-persona di path:

`users/{uid}/personaChats/{persona}/messages/{messageId}`

Field yang disimpan di setiap document `messages/{messageId}`:

- `sender` (string): `"user"` atau `"bot"`
- `message` (string): isi pesan
- `persona` (string): contoh `"Past Self"`, `"Ideal Self"`, `"Future Self"`
- `timestamp` (timestamp): waktu (biasanya server timestamp)

### Example structure (buat debugging di Firestore Console)

Contoh data yang akan kamu lihat:

- `users`
  - `{uid}`
    - `personaChats`
      - `Past Self`
        - `messages`
          - `{messageId}`
            - `sender`: `"user"`
            - `message`: `"Halo, aku lagi capek..."`
            - `persona`: `"Past Self"`
            - `timestamp`: `2026-04-25T12:34:56Z`
          - `{messageId}`
            - `sender`: `"bot"`
            - `message`: `"Aku ngerti... jangan takut ya."`
            - `persona`: `"Past Self"`
            - `timestamp`: `2026-04-25T12:34:57Z`

### Firestore Security Rules

Rules ada di file `firestore.rules` dan membatasi:

- user **hanya bisa read/write** di `users/{uid}/...` miliknya sendiri
- akses user lain **ditolak**

### Cara apply rules di Firebase Console

1. Buka **Firebase Console** → pilih project AlterEgo.
2. Masuk ke **Firestore Database** → tab **Rules**.
3. Copy isi file `firestore.rules` dari repo ini ke editor Rules.
4. Klik **Publish**.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
