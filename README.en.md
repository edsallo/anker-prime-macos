# Anker Prime for macOS

[Русская документация — основной язык](README.md)

An unofficial standalone application for **Anker Prime A2345, 250 W, six USB ports**. It connects directly to the Anker cloud. **The application works only when the charger is connected via Wi-Fi with internet access.**

## Download and install

Download `Anker-Prime-macOS-Apple-Silicon.dmg` from **[Releases](https://github.com/edsallo/anker-prime-macos/releases/latest)**.

### Requirements

- An Apple Silicon Mac (M1 or later), running **macOS 14 Sonoma or later**. The supplied build does not support Intel Macs.
- An A2345 already paired with the original Anker app and connected to Wi-Fi with internet access.
- An Anker account email and password.

Node.js is bundled. Installing development tools is **not necessary** to use the DMG.

1. Open Releases and download the DMG from Assets.
2. Double-click the downloaded file.
3. Drag **Anker Prime.app** onto the **Applications** shortcut.
4. Wait for copying to finish and eject the Anker Prime disk in Finder.
5. Open **Applications → Anker Prime**.

The build is locally signed but **not Apple-notarized**. macOS may block its first launch. If you downloaded it from this repository and trust it, use the app-specific opening permission offered by macOS in **System Settings → Privacy & Security** after attempting to open it. Exact labels vary by OS version. Do not disable Gatekeeper globally.

## First connection

Enter the email and password used in your Anker phone app, choose the cloud region and account registration country, then select Connect charger. Wait for your station to appear online. No account or password is embedded in the release.

If no station appears, check the account, region, country and connectivity in the original app. Direct Apple/Google sign-in without a separate Anker password is not implemented.

## Features

| Area | Capabilities |
|---|---|
| Telemetry | Power, voltage and current for C1–C4, A1 and A2 |
| Power | Individual USB-C switches; a shared switch for A1/A2 |
| Charging modes | AI Power, connection priority, dual laptop, low power and Custom |
| Limits | USB-C limits in 5 W steps; automatic reduction of other limits to fit the 250 W budget |
| Cloud profiles | Create, edit, delete and apply up to four profiles shared with Anker |
| Timers | Auto-off timer in minutes, cancellation and a countdown showing seconds |
| Schedules | Weekly power-on and power-off schedules |
| Energy | USB energy since reset in Wh, approximate mAh equivalent at 3.7 V, counter resets |
| History | Power, voltage and current charts; period energy, peak power, charging time and data coverage |
| Station settings | Brightness, screensaver, screen timeout, clock format/schedule, holiday decoration, dial direction and port priority |
| Experimental features | Maximum compatibility, Custom profiles and device identification |
| Identification | Anker mappings, confirmed VID/PID observations and local model corrections |
| Names | Personal names assigned to ports |
| Appearance | Anker light, Mint, Ocean, Graphite and Sand |
| Language | Automatic macOS language selection, or manual Russian/English selection in Settings |

A1 and A2 have separate readings but share power control, limit and an energy counter. Availability depends on firmware and Anker cloud features. Arbitrary fixed output voltage and firmware management are not implemented. This is not a USB-PD protocol analyzer.

### Energy calculation

The accumulated Wh counter is calculated **by this application**, using the average of adjacent USB power measurements multiplied by their time interval. Gaps longer than 30 seconds, restarts and time while the app is closed are not extrapolated. It represents estimated USB output energy, not electricity drawn from the wall.

`mAh ≈ Wh / 3.7 × 1000` is a nominal battery-voltage equivalent, **not measured battery capacity**. Cable losses, device conversion losses and power used by the device itself are excluded. Do not apply the charger's AC-to-USB efficiency again: USB measurements already follow those losses.

### Identification

The hybrid database combines Anker's model table, confirmed observations and user corrections. VID/PID may identify a model family rather than an individual device. Unknown identities are not guessed. Personal names belong to ports; device and profile names are not automatically translated.

## Language and appearance

Anker light is the default theme. Themes are selected in the header. **Settings → Interface language** offers System language, Русский and English. System mode uses Russian for a Russian macOS language and English otherwise. Choices persist after restarting.

## Local data and privacy

Data is stored in `~/Library/Application Support/Anker Prime`: encrypted credentials, encryption key, history, energy counters and local model corrections. Theme and language choices use macOS preferences. Data is independent of NAS/Beelink installations.

The encryption key is on the same Mac. Encryption prevents plaintext password storage but does not protect against access to your macOS user account. Do not publish this data folder.

The internal service binds only to `127.0.0.1`, uses an automatically chosen port and requires a random per-launch session key. It is not exposed to the LAN. The native window uses a nonpersistent WebKit session and restricts navigation to its local origin. Internet access is needed for Anker cloud connectivity.

Collection stops when the app quits. Timers and schedules already sent to the charger continue on the charger. To update, quit the app and replace it with the new DMG version; local data is retained. Removing the app does not remove its data folder. Deleting that folder removes local history, counters and the saved account.

## Build from source

Backend source is included in `backend/`; a sibling checkout is not required. Build requirements: Apple Silicon, macOS 14+, Python 3, Node.js 22+ with npm and Xcode Command Line Tools.

```sh
xcode-select --install
git clone https://github.com/edsallo/anker-prime-macos.git
cd anker-prime-macos
npm ci --prefix backend
python3 build.py
node --test test/desktop.test.js
npm test --prefix backend
python3 create-dmg.py
```

`build.py` finds Node on PATH. Set `NODE_BINARY=/absolute/path/to/node` to override it. Node is bundled into the generated `dist/Anker Prime.app`. The Swift shell targets arm64 and receives an ad-hoc signature. `create-dmg.py` packages it with an Applications shortcut. Developer ID signing and notarization require a separate Apple Developer account and are not configured.

## Source layout

- `src/AnkerPrime.swift`: native AppKit/WKWebView window, service lifecycle and language/theme persistence.
- `src/desktop-server.js`: isolated loopback session.
- `src/appearance/`: compact layout, themes and translation.
- `backend/`: cloud backend, protocol, UI, history and tests.
- `build.py`, `create-dmg.py`: app and DMG build scripts.

## Licensing

Source code uses the MIT license: [LICENSE](LICENSE). Node's license is included in the application and in [NODE-LICENSE.txt](NODE-LICENSE.txt). Dependencies retain their own licenses.

This is an **unofficial project**, not affiliated with Anker Innovations. Anker branding and the original Anker icon belong to their respective owners and are not licensed under the project's MIT license. The cloud protocol is unofficially researched; changes to Anker services may require updates.
