import { Link } from 'react-router-dom'
import { Mic, History, Cpu, ArrowRight } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

export function HomePage() {
  const features = [
    {
      icon: Mic,
      title: 'Transcribe Audio',
      description: 'Upload audio or video files and get accurate transcriptions using Whisper AI.',
      link: '/transcribe',
      linkText: 'Start Transcribing'
    },
    {
      icon: History,
      title: 'Transcription History',
      description: 'View and manage all your past transcriptions in one place.',
      link: '/history',
      linkText: 'View History'
    },
    {
      icon: Cpu,
      title: 'Model Management',
      description: 'Download and manage different Whisper models for various accuracy and speed needs.',
      link: '/models',
      linkText: 'Manage Models'
    }
  ]

  return (
    <div className="space-y-8">
      <div className="text-center space-y-4">
        <h1 className="text-4xl font-bold tracking-tight">
          Welcome to Open Transcribe WebApp
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          A powerful, privacy-focused web application for audio/video transcription 
          using OpenAI's Whisper model running entirely on your local machine.
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        {features.map((feature) => (
          <Card key={feature.title} className="relative overflow-hidden">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-primary/10">
                  <feature.icon className="h-6 w-6 text-primary" />
                </div>
                <CardTitle className="text-lg">{feature.title}</CardTitle>
              </div>
              <CardDescription className="mt-2">
                {feature.description}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Link to={feature.link}>
                <Button variant="outline" className="w-full group">
                  {feature.linkText}
                  <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                </Button>
              </Link>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card className="bg-muted/50">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className="p-2 rounded-lg bg-primary/10">
              <Mic className="h-6 w-6 text-primary" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold mb-2">Privacy First</h3>
              <p className="text-sm text-muted-foreground">
                All transcription happens locally on your machine. Your audio files and 
                transcriptions never leave your computer, ensuring complete privacy and security.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}