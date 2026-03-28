# 🎙️ Open Transcribe - Local Transcription

A powerful, privacy-focused web application for audio/video transcription using OpenAI's Whisper model running entirely on your local machine.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Python](https://img.shields.io/badge/python-3.10%2B-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

- **Privacy First**: All processing happens locally — your data never leaves your machine
- **Single File Transcription**: Upload and transcribe individual audio/video files with real-time progress
- **Batch Transcription**: Upload and transcribe multiple files simultaneously with parallel processing and per-file progress tracking
- **Multiple Formats**: Support for MP3, WAV, M4A, FLAC, OGG, MP4, MKV, AVI, MOV, WebM
- **Real-time Progress**: Live progress updates during transcription
- **Multiple Export Formats**: Export to TXT, SRT, VTT, JSON
- **Batch Export**: Export all completed batch transcriptions in one click
- **Model Management**: Download and manage different Whisper models
- **Transcription History**: Browse and search past transcriptions
- **Dark/Light Theme**: Customizable appearance
- **Responsive Design**: Works on desktop and tablet

## 🖥️ System Requirements

### Prerequisites

- **Python 3.10+** — [Download Python](https://www.python.org/downloads/)
- **Node.js 18+** — [Download Node.js](https://nodejs.org/)
- **FFmpeg** — Required for audio/video processing
  - macOS: `brew install ffmpeg`
  - Ubuntu/Debian: `sudo apt install ffmpeg`
  - Windows: Download from [ffmpeg.org](https://ffmpeg.org/download.html)

### Minimum Hardware

- 8 GB RAM
- 10 GB free disk space

### Recommended Hardware

- 16+ GB RAM
- NVIDIA GPU with 8GB+ VRAM (for significantly faster transcription)
- 50 GB SSD

## 📦 How to Install

### Quick Install (macOS — No Terminal Needed)

[⬇️ Download Open Transcribe for macOS](https://github.com/YannSTHLM/open-transcribe/releases/latest/download/Open-Transcribe-macOS.dmg)

1. Download the `.dmg` file using the link above
2. Open the downloaded `.dmg`
3. Drag **Open Transcribe** to your **Applications** folder
4. Double-click **Open Transcribe** to launch
5. On first launch, the app opens your browser automatically — no other software needed

> **⚠️ macOS Gatekeeper Warning (unsigned app):**
>
> Since this app is not signed with an Apple Developer certificate, macOS will show a warning. To bypass it, use **any** of these methods:
>
> **Method 1 — Right-click to open:**
> 1. **Right-click** (or Control-click) on **Open Transcribe**
> 2. Select **Open** from the menu
> 3. Click **Open** in the confirmation dialog
>
> **Method 2 — System Settings:**
> 1. Try to open the app (it will be blocked)
> 2. Open **System Settings → Privacy & Security**
> 3. Scroll down and click **Open Anyway** next to the security warning
>
> **Method 3 — Terminal command:**
> ```bash
> xattr -cr /Applications/Open\ Transcribe.app
> ```
> Then double-click the app to open it normally.

### Developer Install (Clone & Run)

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd whisper-webapp
```

### 2. Backend Setup

```bash
cd backend

# Create a virtual environment
python3 -m venv venv

# Activate the virtual environment
# macOS/Linux:
source venv/bin/activate
# Windows:
.\venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Copy the environment configuration file
cp .env.example .env
```

### 3. Frontend Setup

In a new terminal:

```bash
cd frontend

# Install Node.js dependencies
npm install
```

### 4. Start the Application

You need two terminal windows/tabs — one for the backend and one for the frontend.

**Terminal 1 — Backend:**

```bash
cd backend
source venv/bin/activate       # macOS/Linux
# .\venv\Scripts\activate      # Windows
python3 -m app.main
```

The backend API will be available at http://localhost:8000

**Terminal 2 — Frontend:**

```bash
cd frontend
npm run dev
```

The web interface will be available at http://localhost:5173

### 5. Download a Whisper Model

On first use, you'll need to download a Whisper model:

1. Open http://localhost:5173 in your browser
2. Go to the **Models** page in the sidebar
3. Click **Download** on the **base** model (recommended for starting)
4. Wait for the download to complete

You're ready to transcribe! 🎉

## 🎯 Usage

### Transcribing a Single File

1. Navigate to the **Transcribe** page
2. Drag & drop or click to select an audio/video file
3. Choose a model and language
4. Click **Start Transcription**
5. Watch real-time progress updates
6. Export in your preferred format (TXT, SRT, VTT, JSON)

### Batch Transcribing Multiple Files

1. Navigate to the **Batch Transcribe** page
2. Drag & drop or click to select multiple audio/video files
3. Choose a model and language (applied to all files)
4. Click **Start Batch Transcription**
5. Monitor per-file progress in real time
6. Once completed, use **Export All** to download transcriptions in bulk (TXT, SRT, VTT, or JSON)

### Managing Models

1. Go to the **Models** page
2. View available models with size and accuracy info
3. Download models as needed
4. Delete unused models to free up space

### Viewing History

1. Visit the **History** page
2. Search through past transcriptions
3. View, export, or delete transcriptions

## 🖥️ Building the macOS App (Developers)

The macOS app is a self-contained PyInstaller bundle — no Python, Node.js, or FFmpeg installation needed by end users.

```bash
bash scripts/mac/build-app.sh    # Creates build/Open Transcribe.app
bash scripts/mac/build-dmg.sh    # Creates build/Open-Transcribe-macOS.dmg
```

### Windows

#### Option A: Quick Start (PowerShell)

1. Open **PowerShell** (press `Win + X`, select "PowerShell")
2. Navigate to the project folder:
   ```powershell
   cd C:\path\to\whisper-webapp
   ```
3. **First run — install everything and start the app:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\windows\install.ps1; powershell -ExecutionPolicy Bypass -File scripts\windows\start.ps1
   ```
   This single command will:
   - ✓ Check for and install **Python 3.12** via winget
   - ✓ Check for and install **Node.js 20** via winget
   - ✓ Check for and install **FFmpeg** via winget
   - ✓ Create a Python virtual environment
   - ✓ Install all Python packages
   - ✓ Install all Node.js packages
   - ✓ Start both servers and open the app in your browser

4. **To stop the app later:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\windows\stop.ps1
   ```

5. **To start again (no re-install needed):**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\windows\start.ps1
   ```

#### Option B: Double-Click Launcher

Just **double-click `scripts\windows\launcher.vbs`** — it will:
- Detect if this is the first run (no virtual environment exists)
- Automatically run the installer on first run
- Start the app and open the browser

#### Option C: Windows Installer (.exe)

To build a distributable Windows installer:
1. Install [Inno Setup](https://jrsoftware.org/isinfo.php)
2. Open `scripts/windows/build-exe.iss` in Inno Setup
3. Click **Build** to create `OpenTranscribe-Setup-Windows.exe` in the `build/` folder
4. Share the `.exe` — users just run it, then double-click the desktop shortcut

## 📁 Project Structure

```
whisper-webapp/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/  # API endpoints
│   │   ├── models/            # Database models
│   │   ├── services/          # Business logic
│   │   ├── config.py          # Configuration
│   │   └── main.py            # FastAPI app
│   ├── data/                  # Uploads and transcriptions
│   └── requirements.txt       # Python dependencies
│
├── frontend/
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── pages/             # Page components
│   │   ├── lib/               # Utilities
│   │   └── styles/            # CSS styles
│   ├── package.json           # Node dependencies
│   └── vite.config.ts         # Vite configuration
│
├── scripts/
│   ├── mac/                   # macOS install/start/stop/build scripts
│   │   ├── install.sh         # First-run dependency installer
│   │   ├── start.sh           # Start both servers + open browser
│   │   ├── stop.sh            # Stop both servers
│   │   ├── OpenTranscribe.applescript  # .app wrapper
│   │   ├── build-app.sh       # Build macOS .app bundle
│   │   └── build-dmg.sh       # Build macOS .dmg installer
│   └── windows/               # Windows install/start/stop scripts
│       ├── install.ps1        # First-run dependency installer
│       ├── start.ps1          # Start both servers + open browser
│       ├── stop.ps1           # Stop both servers
│       ├── launcher.vbs       # Double-click launcher
│       └── build-exe.iss      # Inno Setup installer config
│
└── README.md
```

## 🔧 Configuration

### Backend Configuration

Edit `backend/.env` to customize:

```env
# Whisper Settings
DEFAULT_MODEL=base          # Model to use by default
USE_GPU=true                # Use GPU if available

# File Upload Settings
MAX_UPLOAD_SIZE=524288000   # 500MB max file size

# Storage Settings
UPLOAD_DIR=./data/uploads
TRANSCRIPTION_DIR=./data/transcriptions
```

### Frontend Configuration

Edit `frontend/.env.local`:

```env
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000
```

## 🧠 Available Models

| Model | Size | VRAM | Accuracy | Best For |
|-------|------|------|----------|----------|
| tiny | 39 MB | 1 GB | 6.5/10 | Quick drafts |
| base | 74 MB | 1 GB | 7.5/10 | General use |
| small | 244 MB | 2 GB | 8.0/10 | Better accuracy |
| medium | 769 MB | 5 GB | 8.5/10 | High accuracy |
| large-v3 | 2.9 GB | 10 GB | 9.0/10 | Best accuracy |

## 🔌 API Reference

The backend provides a REST API at `http://localhost:8000/api/v1/`:

### Transcriptions

- `POST /transcriptions` — Upload and transcribe a single file
- `POST /transcriptions/batch` — Upload and transcribe multiple files in batch
- `GET /transcriptions` — List all transcriptions
- `GET /transcriptions/{id}` — Get transcription details
- `DELETE /transcriptions/{id}` — Delete a transcription
- `GET /transcriptions/{id}/export?format=txt` — Export transcription (TXT, SRT, VTT, JSON)

### Models

- `GET /models` — List available models
- `POST /models/{name}/download` — Download a model
- `DELETE /models/{name}` — Delete a model

### System

- `GET /health` — Health check
- `GET /system/info` — System information

## 🛠️ Development

### Backend Development

```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

### Running Tests

```bash
# Backend tests
cd backend
pytest

# Frontend tests
cd frontend
npm run test
```

## 🐳 Docker Deployment

```bash
# Build and run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 🔒 Privacy & Security

- **No Cloud Processing**: All transcription happens on your local machine
- **No Data Collection**: Your files and transcriptions are never sent to external servers
- **Offline Capable**: Works without internet after initial model download
- **Local Storage**: All data stored in local SQLite database

## 📝 License

MIT License — see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenAI Whisper](https://github.com/openai/whisper) — The core speech recognition model
- [faster-whisper](https://github.com/guillaumekln/faster-whisper) — Optimized Whisper implementation
- [FastAPI](https://fastapi.tiangolo.com/) — Modern Python web framework
- [React](https://react.dev/) — UI library
- [Tailwind CSS](https://tailwindcss.com/) — CSS framework

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📧 Support

For issues and questions:
- Open an issue on GitHub
- Check the documentation

---

**Made with ❤️ for privacy-conscious users**