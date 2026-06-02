# Git Switch

<p align="center">
  <img src="Git Switch/Assets.xcassets/AppIcon.appiconset/256.png" alt="Git Switch Icon" width="128" height="128">
</p>

<p align="center">
  <strong>Effortlessly manage multiple Git identities on macOS</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#building-from-source">Building</a>
</p>

---

## Overview

**Git Switch** is a native macOS menu bar application that helps developers seamlessly manage multiple Git identities. Whether you're juggling work and personal projects, or contributing to various organizations, Git Switch automatically applies the correct Git configuration based on your project folder.

No more accidentally committing with the wrong email! 🎉

## Features

### 🔄 Context-Based Identity Switching
Create folder-specific Git profiles that automatically activate when working in designated directories. Each profile maintains its own:
- Git username
- Email address
- SSH key (auto-generated)

### 🔐 Automatic SSH Key Management
Git Switch automatically generates **ed25519 SSH keys** for each profile and:
- Creates unique keys per identity
- Adds keys to macOS Keychain via `ssh-add`
- Configures the correct SSH key per repository context
- One-click copy of public keys to clipboard

### 📋 Menu Bar Quick Access
Access your Git identities instantly from the macOS menu bar:
- View current global identity at a glance
- See all configured profiles
- Copy SSH keys with one click
- Refresh configurations instantly
- Open the full app window when needed

### 🎨 Customizable Appearance
Personalize the app to match your style:

| Accent Colors | Appearance Modes |
|--------------|------------------|
| 🔵 Blue | ☀️ Light |
| 🟣 Purple | 🌙 Dark |
| 🩷 Pink | 🔄 System |
| 🟠 Orange | |
| 🟢 Green | |
| 🩵 Teal | |

### ✏️ Global Identity Editor
Easily view and modify your global Git configuration directly from the app.

### 🪶 Lightweight & Native
- Built with SwiftUI for a modern, native macOS experience
- Minimal resource usage
- Lives quietly in your menu bar
- No Electron, no web views – pure native performance

## Installation

### Option 1: Download Release (Recommended)
1. Download the latest `.dmg` file from the [Releases](../../releases) page
2. Open the DMG and drag **Git Switch** to your Applications folder
3. Launch Git Switch from Applications
4. Grant necessary permissions when prompted

### Option 2: Build from Source
See [Building from Source](#building-from-source) below.

## Usage

### Getting Started

1. **Launch Git Switch** – The app icon appears in your menu bar
2. **Set Global Identity** – Click the menu bar icon and verify your global Git identity
3. **Create Your First Profile** – Click "Open App" → "+" button

### Creating a Profile

1. Click the **+** button in the main window
2. Fill in the profile details:
   - **Profile Name**: A descriptive name (e.g., "Work", "Personal", "Open Source")
   - **Email**: The email address for this identity
   - **Folder**: The root folder where this identity should apply
3. Click **Create**

Git Switch will automatically:
- Generate a unique SSH key for this profile
- Add the key to your SSH agent
- Configure Git's `includeIf` directive in `~/.gitconfig`
- Create a profile-specific config file

### Copying SSH Keys

To add your SSH key to GitHub, GitLab, or other services:
1. Find your profile in the app or menu bar
2. Click the **key icon** 🔑
3. The public key is copied to your clipboard
4. Paste it into your Git hosting service's SSH settings

### Editing Profiles

1. Hover over a profile card
2. Click the **pencil icon** ✏️
3. Update the name or email
4. Click **Save**

### Deleting Profiles

1. Hover over a profile card
2. Click the **trash icon** 🗑️
3. Confirm deletion

> **Note**: Deleting a profile removes the Git configuration but preserves the SSH key files.

## How It Works

Git Switch leverages Git's powerful [conditional includes](https://git-scm.com/docs/git-config#_conditional_includes) feature.

### Under the Hood

When you create a profile, Git Switch:

1. **Generates an SSH Key**
   ```
   ~/.ssh/id_ed25519_<profile_name>
   ~/.ssh/id_ed25519_<profile_name>.pub
   ```

2. **Creates a Profile Config** (`~/.gitconfig_<profile_name>`)
   ```ini
   [user]
       name = Your Name
       email = your.email@example.com
   [core]
       sshCommand = "ssh -i ~/.ssh/id_ed25519_<profile_name>"
   ```

3. **Updates Global Config** (`~/.gitconfig`)
   ```ini
   [includeIf "gitdir:/Users/you/Projects/Work/"]
       path = /Users/you/.gitconfig_work
   ```
   Folder paths are stored as absolute, fully-resolved paths (symlinks like
   `/tmp` → `/private/tmp` are canonicalized) so they match the path Git actually
   tests. Blocks are kept sorted by specificity — the most specific folder wins, so
   a profile for `…/Projects/Work/Client` correctly overrides one for `…/Projects/Work`.

### The Magic

When you run any Git command in a folder matching the `gitdir` pattern, Git automatically:
- Uses the profile's name and email for commits
- Uses the profile's SSH key for remote operations

## Building from Source

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later
- `git` available on your `PATH` (the app shells out to it)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/git-switch.git
   cd git-switch
   ```

2. **Open in Xcode**
   ```bash
   open "Git Switch.xcodeproj"
   ```

3. **Build and Run**
   - Select your Mac as the build target
   - Press `⌘R` to build and run

### Creating a Release Build

1. In Xcode, select **Product** → **Archive**
2. In the Organizer, click **Distribute App**
3. Choose **Copy App** for local distribution
4. Create a DMG (see below)

### Creating a DMG

Use the bundled script, which auto-detects the built app's version and packages it:

```bash
./scripts/create-dmg.sh "/path/to/Git Switch.app"
```

## Permissions

Git Switch requires the following permissions:

| Permission | Reason |
|------------|--------|
| File System Access | Read/write Git config files and SSH keys |

> **Note:** Git Switch is intentionally **not sandboxed** — it must read and write
> `~/.gitconfig` and `~/.ssh` and run `git`/`ssh-keygen`/`ssh-add`. As a result it
> **cannot be distributed via the Mac App Store**; distribute it as a Developer ID
> signed + notarized DMG (or run it locally from a build).

## Troubleshooting

### SSH Key Not Working

1. Ensure the SSH key was added to the agent:
   ```bash
   ssh-add -l
   ```

2. Verify the public key is added to your Git host

3. Test SSH connection:
   ```bash
   ssh -T git@github.com
   ```

### Identity Not Switching

1. Ensure the folder path in your profile ends with `/`
2. Verify you're inside a Git repository within that folder
3. Check your `~/.gitconfig` for the `includeIf` block
4. Test with:
   ```bash
   cd ~/YourProjectFolder
   git config user.email
   ```

### Menu Bar Icon Missing

1. Check System Settings → Control Center → Menu Bar Only
2. Try quitting and relaunching the app
3. Ensure the app has permission to show menu bar items

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is available under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Inspired by the need to manage multiple Git identities efficiently
- Icon designed for macOS Big Sur+ design language

---

<p align="center">
  Made with ❤️ for developers who juggle multiple Git identities
</p>
