import { useState, useEffect } from 'react'
import { Settings, Monitor, Moon, Sun, Globe, Database, Info } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

interface SystemInfo {
  version: string
  platform: string
  processor: string
  python_version: string
  memory: {
    total: number
    available: number
    used_percent: number
  }
  gpu: {
    available: boolean
    devices: Array<{
      id: number
      name: string
      memory_total: number
    }>
  }
  storage: {
    total: number
    used: number
    free: number
  }
}

export function SettingsPage() {
  const [theme, setTheme] = useState<'light' | 'dark' | 'system'>('system')
  const [defaultModel, setDefaultModel] = useState('base')
  const [defaultLanguage, setDefaultLanguage] = useState('auto')
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchSystemInfo()
  }, [])

  const fetchSystemInfo = async () => {
    try {
      const response = await fetch('/api/v1/system/info')
      const data = await response.json()
      setSystemInfo(data)
    } catch (error) {
      console.error('Failed to fetch system info:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleThemeChange = (newTheme: 'light' | 'dark' | 'system') => {
    setTheme(newTheme)
    if (newTheme === 'dark') {
      document.documentElement.classList.add('dark')
    } else if (newTheme === 'light') {
      document.documentElement.classList.remove('dark')
    } else {
      // System preference
      if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    }
  }

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Settings</h1>
        <p className="text-muted-foreground">
          Configure your Open Transcribe preferences
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              General Settings
            </CardTitle>
            <CardDescription>
              Customize your transcription experience
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="text-sm font-medium">Default Model</label>
              <select
                value={defaultModel}
                onChange={(e) => setDefaultModel(e.target.value)}
                className="w-full mt-1 p-2 border rounded-md"
              >
                <option value="tiny">Tiny (fastest)</option>
                <option value="base">Base (recommended)</option>
                <option value="small">Small (better accuracy)</option>
                <option value="medium">Medium (high accuracy)</option>
                <option value="large-v3">Large V3 (best accuracy)</option>
              </select>
            </div>
            <div>
              <label className="text-sm font-medium">Default Language</label>
              <select
                value={defaultLanguage}
                onChange={(e) => setDefaultLanguage(e.target.value)}
                className="w-full mt-1 p-2 border rounded-md"
              >
                <option value="auto">Auto-detect</option>
                <option value="en">English</option>
                <option value="fr">French</option>
                <option value="de">German</option>
                <option value="es">Spanish</option>
                <option value="it">Italian</option>
                <option value="pt">Portuguese</option>
                <option value="nl">Dutch</option>
                <option value="ja">Japanese</option>
                <option value="zh">Chinese</option>
              </select>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Monitor className="h-5 w-5" />
              Appearance
            </CardTitle>
            <CardDescription>
              Customize the look and feel
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div>
              <label className="text-sm font-medium">Theme</label>
              <div className="flex gap-2 mt-2">
                <Button
                  variant={theme === 'light' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleThemeChange('light')}
                >
                  <Sun className="mr-2 h-4 w-4" />
                  Light
                </Button>
                <Button
                  variant={theme === 'dark' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleThemeChange('dark')}
                >
                  <Moon className="mr-2 h-4 w-4" />
                  Dark
                </Button>
                <Button
                  variant={theme === 'system' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleThemeChange('system')}
                >
                  <Monitor className="mr-2 h-4 w-4" />
                  System
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Info className="h-5 w-5" />
            System Information
          </CardTitle>
          <CardDescription>
            Details about your system and hardware
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : systemInfo ? (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <div>
                <p className="text-sm text-muted-foreground">Version</p>
                <p className="font-medium">{systemInfo.version}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Platform</p>
                <p className="font-medium">{systemInfo.platform}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Processor</p>
                <p className="font-medium">{systemInfo.processor}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Python Version</p>
                <p className="font-medium">{systemInfo.python_version}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Memory</p>
                <p className="font-medium">
                  {formatBytes(systemInfo.memory.available * 1024 * 1024)} / {formatBytes(systemInfo.memory.total * 1024 * 1024)} available
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">GPU</p>
                <p className="font-medium">
                  {systemInfo.gpu.available 
                    ? systemInfo.gpu.devices.map(d => d.name).join(', ')
                    : 'Not available'}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Storage</p>
                <p className="font-medium">
                  {formatBytes(systemInfo.storage.free * 1024 * 1024 * 1024)} / {formatBytes(systemInfo.storage.total * 1024 * 1024 * 1024)} free
                </p>
              </div>
            </div>
          ) : (
            <p className="text-muted-foreground">Failed to load system information</p>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Globe className="h-5 w-5" />
            About
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <p className="text-sm text-muted-foreground">
              Open Transcribe is a privacy-focused transcription application that runs entirely on your local machine.
              Your audio files and transcriptions never leave your computer.
            </p>
            <p className="text-sm text-muted-foreground">
              Built with FastAPI, React, and OpenAI's Whisper model.
            </p>
            <div className="flex gap-4 mt-4">
              <Button variant="outline" size="sm">
                <Database className="mr-2 h-4 w-4" />
                View Documentation
              </Button>
              <Button variant="outline" size="sm">
                Report Issue
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}