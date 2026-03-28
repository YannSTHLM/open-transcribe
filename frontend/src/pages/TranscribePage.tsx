import React, { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { Upload, File, X, Mic, Loader2, CheckCircle, AlertCircle } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { formatFileSize, formatDuration } from '@/lib/utils'

interface TranscriptionResult {
  id: string
  text: string
  segments: Array<{
    id: number
    start: number
    end: number
    text: string
  }>
  language: string
  processing_time: number
}

export function TranscribePage() {
  const [file, setFile] = useState<File | null>(null)
  const [isUploading, setIsUploading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [isTranscribing, setIsTranscribing] = useState(false)
  const [transcriptionProgress, setTranscriptionProgress] = useState(0)
  const [result, setResult] = useState<TranscriptionResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [model, setModel] = useState('base')
  const [language, setLanguage] = useState('auto')

  const onDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      setFile(acceptedFiles[0])
      setError(null)
      setResult(null)
    }
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'audio/*': ['.mp3', '.wav', '.m4a', '.flac', '.ogg'],
      'video/*': ['.mp4', '.mkv', '.avi', '.mov', '.webm']
    },
    maxSize: 500 * 1024 * 1024, // 500MB
    multiple: false
  })

  const handleTranscribe = async () => {
    if (!file) return

    setIsUploading(true)
    setUploadProgress(0)
    setError(null)

    try {
      const formData = new FormData()
      formData.append('file', file)
      formData.append('model', model)
      formData.append('language', language)

      const response = await fetch('/api/v1/transcriptions', {
        method: 'POST',
        body: formData
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.detail || 'Upload failed')
      }

      const data = await response.json()
      setUploadProgress(100)
      setIsUploading(false)
      setIsTranscribing(true)

      // Poll for completion
      await pollTranscriptionStatus(data.id)

    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
      setIsUploading(false)
      setIsTranscribing(false)
    }
  }

  const pollTranscriptionStatus = async (transcriptionId: string) => {
    const maxAttempts = 300 // 5 minutes max
    let attempts = 0

    while (attempts < maxAttempts) {
      try {
        console.log(`Polling attempt ${attempts + 1} for transcription ${transcriptionId}`)
        const response = await fetch(`/api/v1/transcriptions/${transcriptionId}`)
        
        if (!response.ok) {
          console.error('Polling response not ok:', response.status, response.statusText)
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }
        
        const data = await response.json()
        console.log('Transcription status:', data.status, 'Progress:', data.progress)

        if (data.status === 'completed') {
          console.log('Transcription completed!')
          setResult(data)
          setIsTranscribing(false)
          setTranscriptionProgress(100)
          return
        } else if (data.status === 'failed') {
          console.error('Transcription failed:', data.error_message)
          throw new Error(data.error_message || 'Transcription failed')
        } else if (data.status === 'processing') {
          // Use actual progress from API
          const progress = data.progress || 0
          console.log('Setting progress to:', progress)
          // Force state update by creating new number
          setTranscriptionProgress(Number(progress))
        }

        await new Promise(resolve => setTimeout(resolve, 1000))
        attempts++
      } catch (err) {
        console.error('Polling error:', err)
        setError(err instanceof Error ? err.message : 'Status check failed')
        setIsTranscribing(false)
        return
      }
    }

    setError('Transcription timed out')
    setIsTranscribing(false)
  }

  const handleReset = () => {
    setFile(null)
    setResult(null)
    setError(null)
    setUploadProgress(0)
    setTranscriptionProgress(0)
  }

  const handleExport = async (format: string) => {
    if (!result) return

    try {
      const response = await fetch(`/api/v1/transcriptions/${result.id}/export?format=${format}`)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `${file?.name}.${format}`
      a.click()
      window.URL.revokeObjectURL(url)
    } catch (err) {
      setError('Export failed')
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Transcribe</h1>
        <p className="text-muted-foreground">
          Upload audio or video files to transcribe using Whisper AI
        </p>
      </div>

      {!file && !result && (
        <Card>
          <CardContent className="pt-6">
            <div
              {...getRootProps()}
              className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
                isDragActive ? 'border-primary bg-primary/5' : 'border-muted-foreground/25'
              }`}
            >
              <input {...getInputProps()} />
              <Upload className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
              {isDragActive ? (
                <p className="text-lg">Drop the file here...</p>
              ) : (
                <div className="space-y-2">
                  <p className="text-lg font-medium">
                    Drag & drop an audio/video file here
                  </p>
                  <p className="text-sm text-muted-foreground">
                    or click to browse
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Supported: MP3, WAV, M4A, FLAC, OGG, MP4, MKV, AVI, MOV, WebM (max 500MB)
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {file && !result && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <File className="h-5 w-5" />
              File Selected
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
              <div>
                <p className="font-medium">{file.name}</p>
                <p className="text-sm text-muted-foreground">
                  {formatFileSize(file.size)}
                </p>
              </div>
              <Button variant="ghost" size="icon" onClick={handleReset}>
                <X className="h-4 w-4" />
              </Button>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="text-sm font-medium">Model</label>
                <select
                  value={model}
                  onChange={(e) => setModel(e.target.value)}
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
                <label className="text-sm font-medium">Language</label>
                <select
                  value={language}
                  onChange={(e) => setLanguage(e.target.value)}
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
            </div>

            {(isUploading || isTranscribing) && (
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  {isUploading ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      <span>Uploading...</span>
                    </>
                  ) : (
                    <>
                      <Mic className="h-4 w-4 animate-pulse" />
                      <span>Transcribing...</span>
                    </>
                  )}
                </div>
                <Progress value={isUploading ? uploadProgress : transcriptionProgress} />
                <p className="text-sm text-muted-foreground text-center">
                  {isUploading ? `${uploadProgress}%` : `${transcriptionProgress.toFixed(1)}%`}
                </p>
              </div>
            )}

            {error && (
              <div className="flex items-center gap-2 p-4 bg-destructive/10 text-destructive rounded-lg">
                <AlertCircle className="h-5 w-5" />
                <span>{error}</span>
              </div>
            )}

            {!isUploading && !isTranscribing && !error && (
              <Button onClick={handleTranscribe} className="w-full">
                <Mic className="mr-2 h-4 w-4" />
                Start Transcription
              </Button>
            )}
          </CardContent>
        </Card>
      )}

      {result && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-500" />
              Transcription Complete
            </CardTitle>
            <CardDescription>
              Language: {result.language.toUpperCase()} • 
              Processing time: {result.processing_time.toFixed(1)}s
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="p-4 bg-muted rounded-lg">
              <p className="whitespace-pre-wrap">{result.text}</p>
            </div>

            <div className="flex flex-wrap gap-2">
              <Button variant="outline" onClick={() => handleExport('txt')}>
                Export TXT
              </Button>
              <Button variant="outline" onClick={() => handleExport('srt')}>
                Export SRT
              </Button>
              <Button variant="outline" onClick={() => handleExport('vtt')}>
                Export VTT
              </Button>
              <Button variant="outline" onClick={() => handleExport('json')}>
                Export JSON
              </Button>
              <Button variant="outline" onClick={handleReset}>
                Transcribe Another
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}