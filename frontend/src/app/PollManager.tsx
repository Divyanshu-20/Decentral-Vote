"use client";

import { useAccount } from 'wagmi';

export default function PollManager() {
  const { address, isConnected } = useAccount();

  if (!isConnected) {
    return (
      <div className="max-w-4xl mx-auto px-6">
        <div className="backdrop-blur-md bg-white/10 rounded-2xl p-8 border border-white/20">
          <h2 className="text-2xl font-bold text-white mb-4 text-center">
            Connect Your Wallet
          </h2>
          <p className="text-white/70 text-center">
            Please connect your wallet to view and participate in polls
          </p>
        </div>
      </div>
    );
  }

  return (
    <div>"Welcome to the App fucker"
    </div>
  );
}

