# 🎮 Cozy Sleep Time Games

Classic 1990s mobile games for children aged 5–6, built as an iOS SwiftUI app.

## Games included

| Game | Description |
|------|-------------|
| 🐍 **Sleepy Apple Muncher** | Grid-based snake with D-pad controls, growing tail and apple food |
| 🃏 **Sleepy Memory Match** | 4×4 emoji card grid with flip animation and match detection |
| 🔨 **Sleepy Mole Bash** | 3×3 mole grid, 30-second timed rounds, score tracking |
| 🏓 **Sleepy Paddle Bounce** | Player vs CPU with drag-to-move paddle and ball physics |
| 🧱 **Sleepy Brick Blast** | 4-row coloured bricks, draggable paddle, 3 lives system |

## Requirements

- iOS 16.0+
- Xcode 15+

## Run in Xcode

1. Open `KidsHappyClassicGames/KidsHappyClassicGames.xcodeproj`
2. Select an iPhone simulator or your device
3. Press ▶️ Run

## Preview on Appetize (no install needed)

👉 https://appetize.io/app/kbcat5fk6zdujoecmfceorj63m

## CI/CD

- **Appetize**: GitHub Actions workflow in `.github/workflows/build-and-upload-appetize.yml`  
  Requires `APPETIZE_API_TOKEN` repository secret.
- **App Store**: Codemagic config in `codemagic.yaml`  
  Requires App Store Connect API key set up in Codemagic dashboard.
