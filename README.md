# Cyber Tycoon 🎲🏙️

A web-first, isometric, Cyberpunk-themed board game built with Flutter.

## 🚀 Features

### Phase 1: Core Loop
- **Isometric Board**: 2.5D visual style with neon aesthetics.
- **Procedural Generation**: Rectangular path generation for 20 tiles.
- **Dice Mechanics**: Animated roll and token movement.

### Phase 2: Tile Logic
- **Tile Types**:
  - 🟢 **Reward**: +Score, +Credits.
  - 🔴 **Penalty**: -Score, -Credits.
  - 🟣 **Event**: Random effects.
  - ⚪ **Start**: Lap bonus.
- **Visual Feedback**: Neon glows and snackbar alerts.

### Phase 3: Local Multiplayer
- **4-Player Support**: Cyan, Purple, Orange, Green players.
- **Turn System**: Auto-rotating turns.
- **HUD**: Multi-player scoreboard and turn indicators.

### Phase 4: Economy System 💰
- **Credits**: Earn and spend system currency.
- **Upgrades**: Purchase "System Upgrades" ($200) to multiply score gains.
- **Dynamic HUD**: Real-time credit tracking.

### Phase 5: Gatekeeper Security 🛡️
- **Firestore Check**: Before rolling or upgrading, the system checks if the "Child Agent Service" is active.
- **Verification**: `isChildAgentActive(id)` queries Firestore.
- **Blocking**: Actions are denied with UI feedback if the agent is offline (>5 mins).

### Phase 6: Online Multiplayer ☁️
- **Supabase Realtime**: Game state (players, scores, positions) synced via Supabase.
- **Listeners**: `GameController` subscribes to DB changes for a single source of truth.
- **Room Management**: Create and Join rooms via unique 4-character codes.

### Phase 10: User Profiles & Specific Usernames 👤
- **Specific Usernames**: Replaced generic "Player 1/2/3/4" with custom user-defined names.
- **Firestore Sync**: User profiles (display names) are persisted in Firebase Firestore.
- **Profile Hub**: Post-login `MainMenuScreen` allows editing names before starting a match.
- **Simplified Login**: Hardcoded `parentId` for a faster, one-field entry flow.

## 🛠️ Tech Stack
- **Framework**: Flutter (Web, Android, Windows)
- **Backend (Game State)**: Supabase (PostgreSQL + Realtime)
- **Backend (Security)**: Firebase Firestore
- **State Management**: Provider (`ChangeNotifier`)
- **Navigation**: GoRouter
- **Styling**: Google Fonts (`Orbitron`, `RobotoMono`)

## 🏃‍♂️ How to Run

1. **Prerequisites**: Flutter SDK installed.
2. **Configuration**:
   - Update `lib/main.dart` with your **Supabase URL** and **Anon Key**.
   - Ensure Firebase is configured (optional for mock mode).
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run**:
   ```bash
   flutter run -d chrome
   ```

## 📂 Project Structure
- `lib/game/`: Core game logic (Controller, Models, SupabaseService).
- `lib/game/screens/`: UI (Board, Menu).
- `lib/gatekeeper/`: Access control (Firestore Logic).

## 🔮 Roadmap
- [x] Phase 1: MVP Core
- [x] Phase 2: Tile Mechanics
- [x] Phase 3: Multiplayer (Local)
- [x] Phase 4: Economy
- [x] Phase 5: Gatekeeper (Real)
- [x] Phase 6: Multiplayer (Online)
- [x] Phase 10: User Profiles & Specific Usernames
- [ ] Phase 7: Event Cards (Deck System)
- [ ] Phase 8: Properties (Tycoon)
- [ ] Phase 9: Save/Load