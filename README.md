# Luminoir: Chronicles

Multiplayer idle RPG raid prototype built with Flutter and Flame.

Fokus project ini sekarang sudah tidak lagi di papan monopoli dan dadu,
tetapi ke **raid boss RPG** dengan sistem Gatekeeper untuk anak.

## 🎮 Overview

- Masuk lewat **Setup Screen** dengan `User ID` anak.
- **GatekeeperService** cek:
  - apakah anak di-whitelist,
  - apakah layanan **Child Agent** dari orang tua sedang online,
  - kalau tidak aktif, user dibawa ke **AccessDeniedScreen**.
- Kalau semua aman, anak diarahkan ke:
  - **Character Select** → pilih job,
  - **Main Menu** → masuk raid, summon, dan fitur meta lain.

Game loop utama saat ini:

- Pilih job: `warrior`, `mage`, `archer`, atau `assassin`.
- Karakter auto-menyerang boss lewat sistem **attack gauge** (idle).
- Setiap beberapa wave muncul **boss** dengan HP yang diskalakan per stage.
- Kalau boss mati:
  - stage naik,
  - progress campaign disimpan.

## ⚔️ Core Systems

- **Raid Player Stats**
  - Job: `warrior`, `mage`, `archer`, `assassin`.
  - Stat utama: Attack, Attack Speed, Crit Chance, HP, Level, EXP.
  - EXP naik → level up → attack dan HP meningkat.

- **Element & Faction System**
  - Faction: Fire, Water, Thunder, Wind, Earth, YinYang.
  - Relasi elemen (rock–paper–scissors-style):
    - Thunder → Earth → Water → Fire → Wind → Thunder.
  - Jika elemen diserang punya kelemahan:
    - damageTakenMultiplier dan accuracyMultiplier disesuaikan.

- **Campaign / Stage System**
  - Stage dan wave berjalan terus selama raid.
  - Boss wave setiap wave ke-10, atau wave 1 di stage 1.
  - Boss HP diskalakan berdasarkan stage.
  - Gagal bunuh boss sebelum timer habis → balik ke wave farming.

- **Economy & Equipment (Prototype)**
  - Gold dan diamonds sudah dimodelkan untuk ekonomi in-game.
  - Sistem equipment bisa menambah attack, attack speed, dan crit.

## 🧭 Meta & UI

- **SetupScreen**: login dengan background ilustrasi dunia Luminoir.
- **MainMenuScreen**:
  - Tombol ke Raid, Summon, Ninja, dan fitur placeholder lain.
  - Sidebar kiri: Leaderboard, Friends, Mailbox (masih placeholder).
  - Sidebar kanan: Store, Fusing, World (roadmap fitur).
- **AccessDeniedScreen**:
  - Menjelaskan kenapa anak tidak boleh masuk (Child Agent offline, dll).

## 🛠️ Tech Stack

- **Framework**: Flutter (Web, Android, Windows)
- **Game Engine**: Flame
- **Backend**:
  - Supabase (game state, profile pemain)
  - Firebase Firestore (Gatekeeper / Child Agent status)
- **State Management**: Provider (`ChangeNotifier`)
- **Navigation**: GoRouter
- **Styling**: Google Fonts

## 🚀 Running Locally

1. Install Flutter SDK.
2. Konfigurasi backend:
   - Isi **Supabase URL** dan **Anon Key** di konfigurasi project.
   - Konfigurasi Firebase (opsional untuk mode mock / pengembangan).
3. Install dependency:

   ```bash
   flutter pub get
   ```

4. Jalankan di web:

   ```bash
   flutter run -d chrome
   ```

## 📂 Project Structure (Ringkas)

- `lib/main.dart` – entry point dan routing (Splash → Setup → Raid).
- `lib/gatekeeper/` – GatekeeperService, SetupScreen, AccessDeniedScreen.
- `lib/game/raid/` – RaidGame, models, systems, dan UI raid.
- `lib/services/` – SupabaseService dan integrasi backend lain.
- `test/` – unit test untuk gatekeeper, identity, dan raid archetypes.

## 🔗 Links

- **Repository**: [github.com/mrizkyandram18/luminoir-chronicles](https://github.com/mrizkyandram18/luminoir-chronicles)

---

Made with ❤️ using Flutter, Supabase, and Firebase.
