# LossOfControlSmart
## Backport LossOfControlSmart from retail for WoW 3.3.5a

An enhanced backport of Blizzard's Loss of Control alerts for WoW 3.3.5a.

This addon displays a prominent alert when your character loses control due to crowd-control effects and spell school lockouts. It adds a modern options panel to customize size, position, sound, and which categories to show. Big new feature is it auto detects CC that isn't in the list currently. It adds a lot of CCs throughout time.

## Features
- **Retail-style alerts** with icon, spell name, countdown, and swipe.
- **Interrupts and school locks** (e.g., Arcane/Fire/Frost lock) with school-specific text.
- **Covers common CC**: Stun, Fear, Horror, Incapacitate (e.g., Gouge), Disorient, Sleep, Sap, Root, Silence, Disarm, Polymorph/Hex, Cyclone, Banish, Shackle Undead, Possess/Mind Control, Charm, Freeze, etc.
- **Options panel (Ace3)** under `Interface → AddOns → LossOfControlSmart` or via `/loc`:
  - Width and Height (scales the entire alert).
  - X/Y offset (default Y = 75) and Lock Frame toggle for dragging.
  - Sound On/Off (default Off).
  - Display mode per category: `Full`, `Silence`, `Interrupt`, `Disarm`, `Root` each configurable as Off / Only Alert / Show Full Duration. All other CCs follow the `Full` setting.
  - Test Alert button that shows a 10s preview for easy positioning.
  - Advanced: Auto Detect CC (learns unknown CC at runtime) and Clear Learned CC.
- **Saved settings** via AceDB (persist across sessions).

## Installation
- Download the repository ZIP and extract the `LossOfControlSmart` folder into `Interface/AddOns/`.
- Use the direct link: [Download ZIP](https://github.com/thierbig/LossOfControlSmart-3.3.5/archive/refs/heads/main.zip)

## Usage
- Open options with `/loc` or `Esc → Interface → AddOns → LossOfControlSmart`.
- In `Frame & Sound`:
  - Toggle `Lock Frame` off, click `Test Alert` (10s), drag to position, release to save, then lock again.
  - Adjust width/height and X/Y to fine-tune. Sound can be toggled at any time.
- In the main section, configure what to show for `Full`, `Silence`, `Interrupt`, `Disarm`, and `Root`.

## Screenshot
<img width="631" height="619" alt="image" src="https://github.com/user-attachments/assets/51efb4f4-c4ba-4952-b19c-922a9aec8e4a" />
<img width="1048" height="194" alt="image" src="https://github.com/user-attachments/assets/eb5a1342-6cec-4613-8086-31e2c53794ab" />


