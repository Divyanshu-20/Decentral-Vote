import { ConnectButton } from '@rainbow-me/rainbowkit';
import PollManager from "./PollManager";

export default function Home() {
  return (
    <div className="min-h-screen bg-black relative">
      {/* Header */}
      <header className="backdrop-blur-xl bg-black/20 border-b border-white/20 shadow-lg">
        <div className="max-w-6xl mx-auto px-6 py-4">
          <div className="flex justify-between items-center">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-black border border-white rounded-lg flex items-center justify-center">
                <span className="text-lg">🗳️</span>
              </div>
              <div>
                <h1 className="text-xl font-bold text-white">
                  DecentralVote
                </h1>
                <p className="text-gray-400 text-xs">Decentralized Voting Platform</p>
              </div>
            </div>
            
            <div>
              <ConnectButton />
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="py-8"> 
        <PollManager />
      </main>
    </div>
  );
}
