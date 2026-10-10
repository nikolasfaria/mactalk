# MacTalk

Push-to-talk dictation for macOS. Press **⌃E** (or any shortcut you set), speak, press it again, and the text is pasted where your cursor is. A small orb at the top of the screen shows while you dictate.

Speech is recognized on your Mac with Parakeet TDT v3 (sherpa-onnx). Nothing is sent to the cloud.

## Install

### Terminal (Homebrew)

```bash
brew tap nikolasfaria/mactalk
brew install --cask mactalk
```

Then open MacTalk from Applications. It is a menu bar app.

### DMG

Download `MacTalk-x.y.z.dmg` from the [latest release](https://github.com/nikolasfaria/mactalk/releases/latest), open it, and drag MacTalk to Applications.

### First launch

1. MacTalk downloads the speech model once (about 640 MB, SHA-256 verified).
2. Allow the **Microphone** when asked.
3. Optional: allow **Accessibility** (Settings → Accessibility → Grant access). It lets MacTalk paste for you. Without it, the text is copied to the clipboard.

The app is not notarized yet. If macOS says it can't verify MacTalk, right-click the app and choose **Open** once, or run:

```bash
xattr -dr com.apple.quarantine /Applications/MacTalk.app
```

## Use

- **Toggle mode** (default): press the shortcut to start, press it again to stop and paste.
- **Hold mode**: dictate while the shortcut is held.
- Change the shortcut and the mode in Settings (menu bar icon → Settings…).
- Interface languages: English, Português (Brasil), Español, Français, Deutsch, Italiano, 日本語, 简体中文. It follows the macOS language.

Dictation recognizes 25 European languages. The interface works in any language, but recognition for Japanese or Chinese needs a different model, which is not included yet.

## Build from source

Requirements: macOS 14+, Apple Silicon, Swift 5.10+ (Command Line Tools are enough).

```bash
git clone https://github.com/nikolasfaria/mactalk.git
cd mactalk
./scripts/bundle.sh        # build/MacTalk.app
./scripts/make-dmg.sh      # build/MacTalk-<version>.dmg
open build/MacTalk.app
```

## Layout

- `Sources/MacTalk/GlobalHotkey.swift`: system-wide shortcut via Carbon (no Accessibility needed).
- `Sources/MacTalk/AudioRecorder.swift`: mic capture to 16 kHz mono and input device selection.
- `Sources/MacTalk/Recognizer.swift`, `Sherpa/`: Parakeet inference through sherpa-onnx.
- `Sources/MacTalk/SpeechModel.swift`: model files, download, checksums.
- `Sources/MacTalk/IslandWindow.swift`: top-center overlay with the Thinking Orb (Libraries.dev).
- `Sources/MacTalk/OnboardingView.swift`: first-run setup.
- `Sources/MacTalk/SettingsView.swift`, `ShortcutRecorder.swift`: settings.
- `Resources/*.lproj`: translations.
- `Vendor/sherpa-onnx/`: prebuilt arm64 dylibs and the C header (Apache-2.0, see `LICENSE`).
- `scripts/`: `bundle.sh`, `make-dmg.sh`, `release-appstore.sh`.

## Release

```bash
./scripts/bundle.sh && ./scripts/make-dmg.sh
gh release create v0.1.0 build/MacTalk-0.1.0.dmg --title "MacTalk 0.1.0" --notes "First release."
```

Then bump `version` in `Casks/mactalk.rb` of the tap repo.
