# Cyber Tycoon 🎲🏙️

A web-first, isometric, Cyberpunk-themed board game built with Flutter with **live multiplayer** and **comprehensive animation system**.

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
- **Verification**: `isChildAgentActive(id)` queries Firestore (5-minute threshold).
- **Blocking**: Actions are denied with UI feedback if the agent is offline.

### Phase 6: Online Multiplayer ☁️
- **Supabase Realtime**: Game state (players, scores, positions) synced via Supabase.
- **Granular Sync**: Optimized bandwidth with position/credits/score-only updates.
- **Listeners**: `GameController` subscribes to DB changes for a single source of truth.
- **Room Management**: Create and Join rooms via unique 4-character codes.

### Phase 10: User Profiles & Specific Usernames 👤
- **Specific Usernames**: Replaced generic "Player 1/2/3/4" with custom user-defined names.
- **Firestore Sync**: User profiles (display names) are persisted in Firebase Firestore.
- **Profile Hub**: Post-login `MainMenuScreen` allows editing names before starting a match.
- **Simplified Login**: Hardcoded `parentId` for a faster, one-field entry flow.

### Phase 11: Animation Layer ✨ **NEW**
- **Flame Engine**: Integrated for high-performance game rendering.
- **Rive Animations**: Vector animations for dice rolls with fallback UI.
- **Lottie Effects**: Particle effects for property upgrades and events.

#### Animation Components:
- **TokenAnimator**: Smooth tile-by-tile movement with `Curves.easeOutBack`.
- **EffectsManager**: Centralized library for:
  - Floating score/credits notifications
  - Property upgrade particle bursts
  - Event card popups with slide-in animation
  - Tile glow effects for ownership visualization
- **DiceAnimation**: Rive-powered dice roll controller.

#### Enhanced UI:
- **HudOverlay**: Real-time player stats with connection status indicator.
- **ActionPanel**: Gatekeeper-aware buttons (Roll, Buy, Upgrade, Save, Load).
- **GameBoardScreenEnhanced**: Modular board screen with integrated animations.

## 🛠️ Tech Stack
- **Framework**: Flutter (Web, Android, Windows)
- **Game Engine**: Flame ^1.20.0
- **Animations**: Rive ^0.13.0, Lottie ^3.2.0
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
   - Add Rive/Lottie assets to `assets/animations/` (optional).
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
- `lib/game/screens/`: UI (Board, Menu, Enhanced Board).
- `lib/game/animations/`: Animation components (TokenAnimator, EffectsManager, DiceAnimation).
- `lib/game/widgets/`: Reusable UI widgets (ActionPanel, HudOverlay).
- `lib/gatekeeper/`: Access control (Firestore Logic).
- `test/`: Comprehensive unit tests (30+ tests).

## 🔮 Roadmap
- [x] Phase 1: MVP Core
- [x] Phase 2: Tile Mechanics
- [x] Phase 3: Multiplayer (Local)
- [x] Phase 4: Economy
- [x] Phase 5: Gatekeeper (Real - 5min threshold)
- [x] Phase 6: Multiplayer (Online - Granular Sync)
- [x] Phase 10: User Profiles & Specific Usernames
- [x] **Phase 11: Animation Layer (Flame/Rive/Lottie) ✨**
- [ ] Phase 7: Event Cards (Deck System)
- [ ] Phase 8: Properties (Tycoon Mode)
- [ ] Phase 9: Save/Load (Enhanced)

## 📊 Quality Metrics
- ✅ **Flutter Analyze:** 0 issues
- ✅ **Unit Tests:** 30+ tests
- ✅ **Code Coverage:** Animation layer, UI widgets, Services
- ✅ **Production Ready:** KISS/DRY principles applied

## 📚 Documentation
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - Detailed changelog
- [TDD Verification Report](https://github.com/mrizkyandram18/monopoly-tycoon/tree/main) - Test coverage & quality metrics
- [Walkthrough](https://github.com/mrizkyandram18/monopoly-tycoon/tree/main) - Feature demonstrations

## 🔗 Links
- **Repository**: [github.com/mrizkyandram18/monopoly-tycoon](https://github.com/mrizkyandram18/monopoly-tycoon)
- **Latest Release**: Phase 11 - Animation Layer

---

**Made with ❤️ using Flutter & Firebase & Supabase**