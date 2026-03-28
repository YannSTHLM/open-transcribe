# Whisper WebApp Frontend

This is the React frontend for the Whisper WebApp, a privacy-focused audio/video transcription application.

## Features

- **Drag & Drop Upload**: Easy file upload with visual feedback
- **Real-time Progress**: Live transcription progress updates
- **Multiple Export Formats**: Export to TXT, SRT, VTT, JSON
- **Model Management**: Download and manage Whisper models
- **Transcription History**: Browse and search past transcriptions
- **Dark/Light Theme**: Customizable appearance
- **Responsive Design**: Works on desktop and tablet

## Tech Stack

- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **shadcn/ui** for accessible UI components
- **Zustand** for state management
- **React Router** for navigation
- **Lucide React** for icons

## Prerequisites

- Node.js 18 or higher
- npm or bun

## Installation

1. Install dependencies:
```bash
npm install
# or
bun install
```

2. Copy environment file:
```bash
cp .env.example .env.local
```

3. Update environment variables in `.env.local` if needed:
```env
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000
```

## Development

Start the development server:
```bash
npm run dev
# or
bun run dev
```

The app will be available at http://localhost:5173

## Building for Production

Build the application:
```bash
npm run build
# or
bun run build
```

Preview the production build:
```bash
npm run preview
# or
bun run preview
```

## Project Structure

```
src/
├── components/
│   ├── ui/           # Reusable UI components
│   ├── layout/       # Layout components (Sidebar, Header)
│   ├── transcription/ # Transcription feature components
│   ├── batch/        # Batch processing components
│   ├── history/      # History feature components
│   └── models/       # Model management components
├── pages/            # Page components
├── hooks/            # Custom React hooks
├── services/         # API services
├── stores/           # Zustand stores
├── types/            # TypeScript type definitions
├── lib/              # Utility functions
└── styles/           # Global styles
```

## Key Components

### Pages
- **HomePage**: Landing page with feature overview
- **TranscribePage**: File upload and transcription interface
- **HistoryPage**: Browse and manage past transcriptions
- **ModelsPage**: Download and manage Whisper models
- **SettingsPage**: Application settings and system info

### UI Components
- **Button**: Customizable button with variants
- **Card**: Content container with header/footer
- **Progress**: Progress bar component
- **Tabs**: Tabbed interface component

## API Integration

The frontend communicates with the FastAPI backend through:
- REST API endpoints for CRUD operations
- WebSocket for real-time progress updates

### Key Endpoints Used
- `POST /api/v1/transcriptions` - Upload and transcribe files
- `GET /api/v1/transcriptions` - List transcriptions
- `GET /api/v1/transcriptions/{id}` - Get transcription details
- `DELETE /api/v1/transcriptions/{id}` - Delete transcription
- `GET /api/v1/transcriptions/{id}/export` - Export transcription
- `GET /api/v1/models` - List available models
- `POST /api/v1/models/{name}/download` - Download model
- `DELETE /api/v1/models/{name}` - Delete model
- `GET /api/v1/system/info` - Get system information

## State Management

Uses Zustand for lightweight state management:
- Transcription state (current file, progress, results)
- UI state (theme, sidebar)
- Settings state (default model, language)

## Styling

Uses Tailwind CSS with custom CSS variables for theming:
- Light and dark mode support
- Custom color palette
- Responsive breakpoints
- Animation utilities

## Keyboard Shortcuts

- `Ctrl/Cmd + U` - Open file upload
- `Ctrl/Cmd + B` - Go to Batch processing
- `Ctrl/Cmd + H` - Go to History
- `Ctrl/Cmd + M` - Go to Models
- `Ctrl/Cmd + ,` - Open Settings
- `Esc` - Cancel current operation

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## Contributing

1. Follow the existing code style
2. Write meaningful commit messages
3. Test your changes thoroughly
4. Update documentation as needed

## License

MIT License - see LICENSE file for details