import { NavLink } from 'react-router-dom'
import { 
  Home, 
  Mic, 
  History, 
  Cpu, 
  Settings,
  FileAudio,
  Layers
} from 'lucide-react'
import { cn } from '@/lib/utils'

const navItems = [
  { to: '/', icon: Home, label: 'Home' },
  { to: '/transcribe', icon: Mic, label: 'Transcribe' },
  { to: '/batch-transcribe', icon: Layers, label: 'Batch Transcribe' },
  { to: '/history', icon: History, label: 'History' },
  { to: '/models', icon: Cpu, label: 'Models' },
  { to: '/settings', icon: Settings, label: 'Settings' },
]

export function Sidebar() {
  return (
    <aside className="fixed left-0 top-0 h-full w-64 bg-card border-r border-border">
      <div className="p-6">
        <div className="flex items-center gap-2 mb-8">
          <FileAudio className="h-8 w-8 text-primary" />
          <span className="text-xl font-bold">Open Transcribe</span>
        </div>
        
        <nav className="space-y-2">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                cn(
                  "flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors",
                  isActive
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                )
              }
            >
              <item.icon className="h-5 w-5" />
              {item.label}
            </NavLink>
          ))}
        </nav>
      </div>
    </aside>
  )
}