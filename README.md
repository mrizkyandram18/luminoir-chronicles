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

## 🛠️ Tech Stack
- **Framework**: Flutter (Web, Android, Windows)
- **State Management**: Provider (`ChangeNotifier`)
- **Navigation**: GoRouter
- **Styling**: Google Fonts (`Orbitron`, `RobotoMono`)

## 🏃‍♂️ How to Run

1. **Prerequisites**: Flutter SDK installed.
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run**:
   ```bash
   flutter run -d chrome
   ```

## 📂 Project Structure
- `lib/game/`: Core game logic (Controller, Models).
- `lib/game/screens/`: UI (Board, Menu).
- `lib/gatekeeper/`: Access control (Mocked).

## 🔮 Roadmap
- [x] Phase 1: MVP Core
- [x] Phase 2: Tile Mechanics
- [x] Phase 3: Multiplayer
- [x] Phase 4: Economy
- [ ] Phase 5: Event Cards
- [ ] Phase 6: Properties (Tycoon)
- [ ] Phase 7: Save/Load