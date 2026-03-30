import { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { Upload, File, X, Mic, Loader2, CheckCircle, AlertCircle, Trash2 } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { formatFileSize } from '@/lib/utils'

interface BatchFile {
  file: File
  id: string
  status: 'pending' | 'uploading' | 'transcribing' | 'completed' | 'failed'
  progress: number
  transcriptionId?: string
  error?: string
}

interface BatchResult {
  batch_id: string
  total_files: number
  successful: number
  failed: number
  results: Array<{
    id: string
    file_name: string
    status: string
  }>
  errors: Array<{
    file: string
    error: string
  }>
}

export function BatchTranscribePage() {
  const [files, setFiles] = useState<BatchFile[]>([])
  const [isProcessing, setIsProcessing] = useState(false)
  const [model, setModel] = useState('base')
  const [language, setLanguage] = useState('auto')
  const [, setBatchResult] = useState<BatchResult | null>(null)

  const onDrop = useCallback((acceptedFiles: File[]) => {
    const newFiles = acceptedFiles.map(file => ({
      file,
      id: Math.random().toString(36).substr(2, 9),
      status: 'pending' as const,
      progress: 0
    }))
    setFiles(prev => [...prev, ...newFiles])
    setBatchResult(null)
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'audio/*': ['.mp3', '.wav', '.m4a', '.flac', '.ogg'],
      'video/*': ['.mp4', '.mkv', '.avi', '.mov', '.webm']
    },
    maxSize: 500 * 1024 * 1024, // 500MB
    multiple: true
  })

  const removeFile = (id: string) => {
    setFiles(prev => prev.filter(f => f.id !== id))
  }

  const clearAll = () => {
    setFiles([])
    setBatchResult(null)
  }

  const pollSingleTranscription = async (
    transcriptionId: string,
    batchFileId: string
  ): Promise<'completed' | 'failed'> => {
    const maxAttempts = 600
    let attempts = 0

    while (attempts < maxAttempts) {
      try {
        const response = await fetch(`/api/v1/transcriptions/${transcriptionId}`)
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`)
        }

        const data = await response.json()

        if (data.status === 'completed') {
          setFiles(prev => prev.map(f =>
            f.id === batchFileId
              ? { ...f, status: 'completed' as const, progress: 100 }
              : f
          ))
          return 'completed'
        } else if (data.status === 'failed') {
          setFiles(prev => prev.map(f =>
            f.id === batchFileId
              ? { ...f, status: 'failed' as const, error: data.error_message || 'Transcription failed' }
              : f
          ))
          return 'failed'
        } else if (data.status === 'processing') {
          const progress = data.progress || 0
          setFiles(prev => prev.map(f =>
            f.id === batchFileId
              ? { ...f, progress: Number(progress) }
              : f
          ))
        }
      } catch (err) {
        console.error('Polling error:', err)
      }

      await new Promise(resolve => setTimeout(resolve, 1000))
      attempts++
    }

    setFiles(prev => prev.map(f =>
      f.id === batchFileId
        ? { ...f, status: 'failed' as const, error: 'Transcription timed out' }
        : f
    ))
    return 'failed'
  }

  const handleBatchTranscribe = async () => {
    // Capture current file IDs and names before any state updates
    const currentFiles = files.map(f => ({ id: f.id, name: f.file.name, file: f.file }))
    if (currentFiles.length === 0) return

    setIsProcessing(true)
    setBatchResult(null)

    try {
      const formData = new FormData()
      files.forEach(f => {
        formData.append('files', f.file)
      })
      formData.append('model', model)
      formData.append('language', language)

      // Update all files to uploading status
      setFiles(prev => prev.map(f => ({ ...f, status: 'uploading' as const, progress: 0 })))

      const response = await fetch('/api/v1/transcriptions/batch', {
        method: 'POST',
        body: formData
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.detail || 'Batch upload failed')
      }

      const data: BatchResult = await response.json()
      setBatchResult(data)

      // Build transcription map from captured currentFiles (not stale state)
      const transcriptionMap: Array<{ batchFileId: string; transcriptionId: string }> = []
      
      data.results.forEach(result => {
        const match = currentFiles.find(cf => cf.name === result.file_name)
        if (match) {
          transcriptionMap.push({ batchFileId: match.id, transcriptionId: result.id })
        }
      })

      // Update files using functional updater to avoid stale state
      setFiles(prev => prev.map(f => {
        const result = data.results.find(r => {
          const match = currentFiles.find(cf => cf.id === f.id)
          return match && r.file_name === match.name
        })
        const error = data.errors.find(e => {
          const match = currentFiles.find(cf => cf.id === f.id)
          return match && e.file === match.name
        })
        
        if (result) {
          return {
            ...f,
            status: 'transcribing' as const,
            transcriptionId: result.id,
            progress: 0
          }
        } else if (error) {
          return {
            ...f,
            status: 'failed' as const,
            error: error.error
          }
        }
        return f
      }))

      // Poll all transcriptions in parallel using the pre-built map
      const pollPromises = transcriptionMap.map(({ batchFileId, transcriptionId }) =>
        pollSingleTranscription(transcriptionId, batchFileId)
      )

      await Promise.all(pollPromises)
      
      setIsProcessing(false)
    } catch (err) {
      setFiles(prev => prev.map(f => ({ 
        ...f, 
        status: 'failed' as const, 
        error: err instanceof Error ? err.message : 'An error occurred' 
      })))
      setIsProcessing(false)
    }
  }

  const handleExportAll = async (format: string) => {
    const completedFiles = files.filter(f => f.status === 'completed' && f.transcriptionId)
    
    for (const file of completedFiles) {
      try {
        const response = await fetch(`/api/v1/transcriptions/${file.transcriptionId}/export?format=${format}`)
        const blob = await response.blob()
        // Use the filename from the Content-Disposition header set by the backend
        const contentDisposition = response.headers.get('Content-Disposition')
        let downloadName = `transcription.${format}`
        if (contentDisposition) {
          const match = contentDisposition.match(/filename=([^;]+)/)
          if (match) {
            downloadName = match[1]
          }
        }
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = downloadName
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (err) {
        console.error('Export failed for', file.file.name)
      }
    }
  }

  const completedCount = files.filter(f => f.status === 'completed').length
  const failedCount = files.filter(f => f.status === 'failed').length
  const processingCount = files.filter(f => f.status === 'transcribing' || f.status === 'uploading').length

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Batch Transcribe</h1>
        <p className="text-muted-foreground">
          Upload multiple audio or video files to transcribe simultaneously
        </p>
      </div>

      {files.length === 0 && (
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
                <p className="text-lg">Drop the files here...</p>
              ) : (
                <div className="space-y-2">
                  <p className="text-lg font-medium">
                    Drag & drop audio/video files here
                  </p>
                  <p className="text-sm text-muted-foreground">
                    or click to browse (multiple files allowed)
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Supported: MP3, WAV, M4A, FLAC, OGG, MP4, MKV, AVI, MOV, WebM (max 500MB each)
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {files.length > 0 && (
        <>
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="flex items-center gap-2">
                  <File className="h-5 w-5" />
                  Files ({files.length})
                </CardTitle>
                <Button variant="outline" size="sm" onClick={clearAll} disabled={isProcessing}>
                  <Trash2 className="h-4 w-4 mr-2" />
                  Clear All
                </Button>
              </div>
              <CardDescription>
                {completedCount} completed • {failedCount} failed • {processingCount} processing
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <label className="text-sm font-medium">Model</label>
                  <select
                    value={model}
                    onChange={(e) => setModel(e.target.value)}
                    className="w-full mt-1 p-2 border rounded-md"
                    disabled={isProcessing}
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
                    disabled={isProcessing}
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

              <div className="space-y-2 max-h-96 overflow-y-auto">
                {files.map((batchFile) => (
                  <div
                    key={batchFile.id}
                    className="flex items-center justify-between p-3 bg-muted rounded-lg"
                  >
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">{batchFile.file.name}</p>
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <span>{formatFileSize(batchFile.file.size)}</span>
                        {batchFile.status === 'transcribing' && (
                          <span>• {batchFile.progress.toFixed(1)}%</span>
                        )}
                      </div>
                      {batchFile.status === 'transcribing' && (
                        <Progress value={batchFile.progress} className="mt-2 h-2" />
                      )}
                      {batchFile.error && (
                        <p className="text-sm text-destructive mt-1">{batchFile.error}</p>
                      )}
                    </div>
                    <div className="flex items-center gap-2 ml-4">
                      {batchFile.status === 'pending' && !isProcessing && (
                        <Button variant="ghost" size="icon" onClick={() => removeFile(batchFile.id)}>
                          <X className="h-4 w-4" />
                        </Button>
                      )}
                      {batchFile.status === 'uploading' && (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      )}
                      {batchFile.status === 'transcribing' && (
                        <Mic className="h-4 w-4 animate-pulse text-primary" />
                      )}
                      {batchFile.status === 'completed' && (
                        <CheckCircle className="h-4 w-4 text-green-500" />
                      )}
                      {batchFile.status === 'failed' && (
                        <AlertCircle className="h-4 w-4 text-destructive" />
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {!isProcessing && files.some(f => f.status === 'pending') && (
                <Button onClick={handleBatchTranscribe} className="w-full">
                  <Mic className="mr-2 h-4 w-4" />
                  Start Batch Transcription ({files.filter(f => f.status === 'pending').length} files)
                </Button>
              )}

              {isProcessing && (
                <div className="flex items-center justify-center gap-2 p-4">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Processing {processingCount} files...</span>
                </div>
              )}
            </CardContent>
          </Card>

          {completedCount > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Export Results</CardTitle>
                <CardDescription>
                  Download transcriptions for {completedCount} completed file(s)
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  <Button variant="outline" onClick={() => handleExportAll('txt')}>
                    Export All TXT
                  </Button>
                  <Button variant="outline" onClick={() => handleExportAll('srt')}>
                    Export All SRT
                  </Button>
                  <Button variant="outline" onClick={() => handleExportAll('vtt')}>
                    Export All VTT
                  </Button>
                  <Button variant="outline" onClick={() => handleExportAll('json')}>
                    Export All JSON
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </>
      )}
    </div>
  )
}