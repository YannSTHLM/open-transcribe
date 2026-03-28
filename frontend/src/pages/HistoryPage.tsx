import { useState, useEffect } from 'react'
import { Search, Download, Trash2, Eye, Clock, FileAudio } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { formatFileSize, formatDuration } from '@/lib/utils'

interface Transcription {
  id: string
  file_name: string
  file_size: number
  duration: number
  model: string
  language: string
  status: string
  created_at: string
  completed_at: string | null
  processing_time: number | null
}

export function HistoryPage() {
  const [transcriptions, setTranscriptions] = useState<Transcription[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedTranscription, setSelectedTranscription] = useState<Transcription | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchTranscriptions()
  }, [])

  const fetchTranscriptions = async () => {
    try {
      const response = await fetch('/api/v1/transcriptions')
      const data = await response.json()
      setTranscriptions(data.items || [])
    } catch (error) {
      console.error('Failed to fetch transcriptions:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this transcription?')) return

    try {
      await fetch(`/api/v1/transcriptions/${id}`, { method: 'DELETE' })
      setTranscriptions(transcriptions.filter(t => t.id !== id))
      if (selectedTranscription?.id === id) {
        setSelectedTranscription(null)
      }
    } catch (error) {
      console.error('Failed to delete transcription:', error)
    }
  }

  const handleExport = async (id: string, format: string) => {
    try {
      const response = await fetch(`/api/v1/transcriptions/${id}/export?format=${format}`)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `transcription.${format}`
      a.click()
      window.URL.revokeObjectURL(url)
    } catch (error) {
      console.error('Failed to export transcription:', error)
    }
  }

  const filteredTranscriptions = transcriptions.filter(t =>
    t.file_name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
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
        <h1 className="text-3xl font-bold">History</h1>
        <p className="text-muted-foreground">
          View and manage your past transcriptions
        </p>
      </div>

      <div className="flex items-center gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search transcriptions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border rounded-md"
          />
        </div>
      </div>

      {filteredTranscriptions.length === 0 ? (
        <Card>
          <CardContent className="pt-6">
            <div className="text-center py-8">
              <FileAudio className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
              <h3 className="text-lg font-medium mb-2">No transcriptions found</h3>
              <p className="text-muted-foreground">
                {searchQuery ? 'Try a different search term' : 'Start by transcribing an audio file'}
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {filteredTranscriptions.map((transcription) => (
            <Card key={transcription.id} className="hover:shadow-md transition-shadow">
              <CardContent className="pt-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <FileAudio className="h-5 w-5 text-primary" />
                      <h3 className="font-medium">{transcription.file_name}</h3>
                      <span className={`px-2 py-1 text-xs rounded-full ${
                        transcription.status === 'completed' 
                          ? 'bg-green-100 text-green-800' 
                          : transcription.status === 'processing'
                          ? 'bg-blue-100 text-blue-800'
                          : transcription.status === 'failed'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {transcription.status}
                      </span>
                    </div>
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <Clock className="h-4 w-4" />
                        {formatDate(transcription.created_at)}
                      </span>
                      <span>{formatFileSize(transcription.file_size)}</span>
                      {transcription.duration && (
                        <span>{formatDuration(transcription.duration)}</span>
                      )}
                      <span className="capitalize">{transcription.model}</span>
                      <span className="uppercase">{transcription.language}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {transcription.status === 'completed' && (
                      <>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setSelectedTranscription(transcription)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleExport(transcription.id, 'txt')}
                        >
                          <Download className="h-4 w-4" />
                        </Button>
                      </>
                    )}
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDelete(transcription.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {selectedTranscription && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <Card className="w-full max-w-2xl max-h-[80vh] overflow-auto">
            <CardHeader>
              <CardTitle>{selectedTranscription.file_name}</CardTitle>
              <CardDescription>
                Transcribed on {formatDate(selectedTranscription.created_at)}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex flex-wrap gap-2">
                  <Button variant="outline" onClick={() => handleExport(selectedTranscription.id, 'txt')}>
                    Export TXT
                  </Button>
                  <Button variant="outline" onClick={() => handleExport(selectedTranscription.id, 'srt')}>
                    Export SRT
                  </Button>
                  <Button variant="outline" onClick={() => handleExport(selectedTranscription.id, 'vtt')}>
                    Export VTT
                  </Button>
                  <Button variant="outline" onClick={() => handleExport(selectedTranscription.id, 'json')}>
                    Export JSON
                  </Button>
                </div>
                <div className="p-4 bg-muted rounded-lg">
                  <p className="whitespace-pre-wrap">
                    Transcription text would appear here after fetching from the API
                  </p>
                </div>
                <Button variant="outline" onClick={() => setSelectedTranscription(null)}>
                  Close
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}