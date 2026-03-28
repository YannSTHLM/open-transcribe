import React, { useState, useEffect } from 'react'
import { Download, Trash2, CheckCircle, HardDrive, Cpu } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'

interface Model {
  name: string
  size_mb: number
  params: string
  vram_gb: number
  accuracy_score: number
  downloaded: boolean
}

export function ModelsPage() {
  const [models, setModels] = useState<Model[]>([])
  const [loading, setLoading] = useState(true)
  const [downloading, setDownloading] = useState<string | null>(null)
  const [downloadProgress, setDownloadProgress] = useState(0)

  useEffect(() => {
    fetchModels()
  }, [])

  const fetchModels = async () => {
    try {
      const response = await fetch('/api/v1/models')
      const data = await response.json()
      setModels(data.models || [])
    } catch (error) {
      console.error('Failed to fetch models:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDownload = async (modelName: string) => {
    setDownloading(modelName)
    setDownloadProgress(0)

    try {
      const response = await fetch(`/api/v1/models/${modelName}/download`, {
        method: 'POST'
      })
      const data = await response.json()

      if (data.status === 'already_downloaded') {
        alert('Model is already downloaded')
        setDownloading(null)
        return
      }

      // Simulate download progress
      const interval = setInterval(() => {
        setDownloadProgress(prev => {
          if (prev >= 95) {
            clearInterval(interval)
            return prev
          }
          return prev + Math.random() * 10
        })
      }, 500)

      // Wait for download to complete (in real app, would poll status)
      await new Promise(resolve => setTimeout(resolve, 5000))
      
      clearInterval(interval)
      setDownloadProgress(100)
      
      // Refresh models list
      await fetchModels()
      
    } catch (error) {
      console.error('Failed to download model:', error)
      alert('Failed to download model')
    } finally {
      setDownloading(null)
      setDownloadProgress(0)
    }
  }

  const handleDelete = async (modelName: string) => {
    if (!confirm(`Are you sure you want to delete the ${modelName} model?`)) return

    try {
      await fetch(`/api/v1/models/${modelName}`, { method: 'DELETE' })
      await fetchModels()
    } catch (error) {
      console.error('Failed to delete model:', error)
      alert('Failed to delete model')
    }
  }

  const getAccuracyColor = (score: number) => {
    if (score >= 8.5) return 'text-green-600'
    if (score >= 7.5) return 'text-yellow-600'
    return 'text-orange-600'
  }

  const getAccuracyLabel = (score: number) => {
    if (score >= 9) return 'Excellent'
    if (score >= 8.5) return 'Very Good'
    if (score >= 7.5) return 'Good'
    return 'Fair'
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Models</h1>
        <p className="text-muted-foreground">
          Download and manage Whisper models for transcription
        </p>
      </div>

      <Card className="bg-muted/50">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <Cpu className="h-6 w-6 text-primary mt-1" />
            <div>
              <h3 className="font-semibold mb-2">Model Selection Guide</h3>
              <ul className="text-sm text-muted-foreground space-y-1">
                <li>• <strong>Tiny/Base:</strong> Fast transcription, lower accuracy. Good for drafts.</li>
                <li>• <strong>Small:</strong> Balanced speed and accuracy for English content.</li>
                <li>• <strong>Medium:</strong> High accuracy English transcription.</li>
                <li>• <strong>Large V3:</strong> Best accuracy, supports 99+ languages. Requires more VRAM.</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {models.map((model) => (
          <Card key={model.name} className="relative">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg capitalize">{model.name}</CardTitle>
                {model.downloaded && (
                  <CheckCircle className="h-5 w-5 text-green-500" />
                )}
              </div>
              <CardDescription>
                {model.params} parameters
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Size</p>
                  <p className="font-medium">{model.size_mb} MB</p>
                </div>
                <div>
                  <p className="text-muted-foreground">VRAM Required</p>
                  <p className="font-medium">{model.vram_gb} GB</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Accuracy</p>
                  <p className={`font-medium ${getAccuracyColor(model.accuracy_score)}`}>
                    {model.accuracy_score}/10 ({getAccuracyLabel(model.accuracy_score)})
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Status</p>
                  <p className={`font-medium ${model.downloaded ? 'text-green-600' : 'text-muted-foreground'}`}>
                    {model.downloaded ? 'Downloaded' : 'Not downloaded'}
                  </p>
                </div>
              </div>

              {downloading === model.name && (
                <div className="space-y-2">
                  <Progress value={downloadProgress} />
                  <p className="text-sm text-center text-muted-foreground">
                    Downloading... {downloadProgress.toFixed(0)}%
                  </p>
                </div>
              )}

              <div className="flex gap-2">
                {!model.downloaded ? (
                  <Button 
                    onClick={() => handleDownload(model.name)}
                    disabled={downloading !== null}
                    className="flex-1"
                  >
                    <Download className="mr-2 h-4 w-4" />
                    Download
                  </Button>
                ) : (
                  <Button 
                    variant="outline"
                    onClick={() => handleDelete(model.name)}
                    className="flex-1"
                  >
                    <Trash2 className="mr-2 h-4 w-4" />
                    Delete
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HardDrive className="h-5 w-5" />
            Storage Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            <div>
              <p className="text-sm text-muted-foreground">Downloaded Models</p>
              <p className="text-2xl font-bold">
                {models.filter(m => m.downloaded).length}
              </p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Total Size</p>
              <p className="text-2xl font-bold">
                {models.filter(m => m.downloaded).reduce((acc, m) => acc + m.size_mb, 0)} MB
              </p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Available Models</p>
              <p className="text-2xl font-bold">{models.length}</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}