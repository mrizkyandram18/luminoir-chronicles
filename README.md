# Luminoir: Chronicles

Multiplayer idle RPG raid prototype built with Flutter and Flame.

Fokus project ini sekarang sudah tidak lagi di papan monopoli dan dadu,
tetapi ke **raid boss RPG** dengan loop idle dan sistem stage/boss.

## 🎮 Overview

- Masuk lewat **Setup Screen** dengan sebuah ID.
- Setelah login, pemain diarahkan ke:
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

- **SetupScreen**: layar login dengan background ilustrasi dunia Luminoir.
- **MainMenuScreen**:
  - Tombol ke Raid, Summon, Ninja, dan fitur placeholder lain.
  - Sidebar kiri: Leaderboard, Friends, Mailbox (masih placeholder).
  - Sidebar kanan: Store, Fusing, World (roadmap fitur).
- **Layar penolakan akses**:
-  - Menjelaskan kenapa akses game ditolak.

## 🛠️ Tech Stack

- **Framework**: Flutter (Web, Android, Windows)
- **Game Engine**: Flame
- **Backend**:
  - Supabase (game state, profile pemain)
  - Firebase Firestore (metadata akses dan status keamanan)
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
- `lib/gatekeeper/` – modul akses dan login, termasuk layar penolakan akses.
- `lib/game/raid/` – RaidGame, models, systems, dan UI raid.
- `lib/services/` – SupabaseService dan integrasi backend lain.
- `test/` – unit test untuk sistem identitas dan raid archetypes.

## 🔗 Links

- **Repository**: [github.com/mrizkyandram18/luminoir-chronicles](https://github.com/mrizkyandram18/luminoir-chronicles)

---

Made with ❤️ using Flutter, Supabase, and Firebase.
