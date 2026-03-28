import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { MainLayout } from './components/layout/MainLayout'
import { HomePage } from './pages/HomePage'
import { TranscribePage } from './pages/TranscribePage'
import { BatchTranscribePage } from './pages/BatchTranscribePage'
import { HistoryPage } from './pages/HistoryPage'
import { ModelsPage } from './pages/ModelsPage'
import { SettingsPage } from './pages/SettingsPage'

function App() {
  return (
    <Router>
      <MainLayout>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/transcribe" element={<TranscribePage />} />
          <Route path="/batch-transcribe" element={<BatchTranscribePage />} />
          <Route path="/history" element={<HistoryPage />} />
          <Route path="/models" element={<ModelsPage />} />
          <Route path="/settings" element={<SettingsPage />} />
        </Routes>
      </MainLayout>
    </Router>
  )
}

export default App