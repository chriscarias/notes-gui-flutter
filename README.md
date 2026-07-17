# Notes API - Flutter Web & Linux Desktop Client

A lightweight Master/Detail layout split-pane client built with Flutter. It communicates with a Go REST API backend via JWT authentication to perform full CRUD operations (Create, Read, Update, Delete) and completion status toggles.

## Prerequisites for Native Linux (Kubuntu 26.04)

To compile and run this application natively on Kubuntu without WSL, you must install the Flutter SDK and the underlying C++/GTK toolchain required by Flutter's engine.

### 1. Install System Build Toolchain
Open a terminal on Kubuntu and install the prerequisites via `apt`:

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

### 2. Install Flutter SDK
The cleanest way to maintain Flutter on Ubuntu/Kubuntu LTS releases is via Snap:

```Bash
sudo snap install flutter --classic
```
Verify the installation and path configurations:

```Bash
flutter doctor
```

Project Recreation from Scratch
If you are initializing this codebase in a clean directory on your laptop, follow these sequential steps:

### 1. Initialize the Flutter Project
Create a empty folder, navigate inside, and scaffold the application layout skeleton:

```Bash
mkdir notes-flutter-client
cd notes-flutter-client
flutter create --platforms=web,linux .
```

### 2. Add the Network Package Dependency
Install the official Flutter HTTP utility package. This automatically modifies your pubspec.yaml configuration file:

```Bash
flutter pub add http
```

### 3. Place Source Files
Ensure your project files match this exact structural mapping inside the directory:

```Plaintext
notes-flutter-client/
├── lib/
│   ├── api_client.dart      # Network HTTP wrapper and JWT processor
│   └── main.dart            # Layout architecture, state, and UI panes
└── pubspec.yaml
```
### Execution Targets
Before running, ensure your Go REST API server is up and active at the address targeted inside lib/main.dart (default: http://localhost:8002).

#### Target Option A: Flutter Web (Recommended Fallback)
Compiles the Dart source code down to HTML5 canvas components, completely bypassing local operating system graphics drivers.

```Bash
# Enable the web compilation engine
flutter config --enable-web

# Run the app as a local development server
flutter run -d web-server --web-port 8080
```
Once compilation finishes, open any browser on your Kubuntu system and navigate to http://localhost:8080.

#### Target Option B: Native Linux Desktop Application
Compiles the application into a native Linux binary running directly on top of your X11 or Wayland display server window manager.

```Bash
# Enable the native Linux build target
flutter config --enable-linux-desktop

# Launch the native desktop client window
flutter run -d linux
```
*Note:* Because this targets your physical GPU hardware directly on native Linux, it avoids the transparent canvas bugs encountered under the Windows 10 WSL graphics layering context.