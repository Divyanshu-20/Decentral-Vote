"use client";

import React from 'react';
import { useAccount } from 'wagmi';
import { useReadContract } from 'wagmi'
import { abi } from '../abi/PollManager.json'
import { useState } from 'react';

// Type definitions for poll details
type PollDetails = {
  0: string; // title
  1: string[]; // options
  2: bigint; // deadline
} | undefined;

export default function PollManager() {
  const { isConnected } = useAccount();
  const [pollId, setPollId] = useState<string>('0'); // Default to poll ID 0
  const [inputValue, setInputValue] = useState<string>(''); // Add this state for input

  // Always call hooks at the top level, before any early returns
  const {
    data: totalPolls,
    isLoading: totalPollsLoading,
    error: totalPollsError
  } = useReadContract({
    abi,
    address: '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512',
    functionName: 'getTotalPolls',
  });

  // Fetch poll details when pollId changes
  const {
    data: pollDetails,
    isLoading: pollDetailsLoading,
    error: pollDetailsError
  } = useReadContract({
    abi,
    address: '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512',
    functionName: 'pollDetails',
    args: [BigInt(pollId)],
    query: {
      enabled: !!pollId && isConnected
    }
  }) as {
    data: PollDetails;
    isLoading: boolean;
    error: Error | null;
  };

  // Fetch poll status (open/closed)
  const {
    data: isPollOpen,
    isLoading: pollStatusLoading,
    error: pollStatusError
  } = useReadContract({
    abi,
    address: '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512',
    functionName: 'isPollOpen',
    args: [BigInt(pollId)],
    query: {
      enabled: !!pollId && isConnected
    }
  }) as {
    data: boolean | undefined;
    isLoading: boolean;
    error: Error | null;
  };

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
    <div className="max-w-4xl mx-auto px-6">
      <div className="backdrop-blur-md bg-white/10 rounded-2xl p-8 border border-white/20">
        <h2 className="text-2xl font-bold text-white mb-6 text-center">
          Poll Manager
        </h2>

        {/* Display loading state */}
        {totalPollsLoading && (
          <p className="text-white/70 text-center">Loading polls...</p>
        )}

        {/* Display error state */}
        {totalPollsError && (
          <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4 mb-4">
            <p className="text-red-200 text-center">
              Error loading polls: {totalPollsError.message}
            </p>
          </div>
        )}

        {/* Display total polls */}
        {totalPolls !== undefined && (
          <div className="bg-blue-500/20 border border-blue-500/50 rounded-lg p-4 mb-6">
            <p className="text-blue-200 text-center">
              Total Polls: <span className="font-bold text-white">{totalPolls !== null ? totalPolls.toString() : "0"}</span>
            </p>
          </div>
        )}

        {/* Poll ID Input Section */}
        <div className="bg-white/5 rounded-lg p-6 mb-6">
          <h3 className="text-lg font-semibold text-white mb-4 text-center">
            Get Poll Details by ID
          </h3>
          <div className="flex items-center gap-3">
            <input
              type="number"
              placeholder="Enter Poll ID"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              className="flex-1 px-4 py-2 border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-gray-900"
            />
            <button
              className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
              onClick={() => setPollId(inputValue)}
              disabled={!inputValue || inputValue === pollId}
            >
              Get Details
            </button>
            {pollId !== '0' && (
              <button
                className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors font-medium"
                onClick={() => {
                  setPollId('0');
                  setInputValue('');
                }}
              >
                Clear
              </button>
            )}
          </div>
        </div>

        {/* Poll Details Display */}
        {pollId !== '0' && (
          <div className="bg-white/5 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-white mb-4 text-center">
              Poll Details (ID: {pollId})
            </h3>

            {/* Loading states */}
            {(pollDetailsLoading || pollStatusLoading) && (
              <div className="text-center">
                <p className="text-white/70">Loading poll details...</p>
              </div>
            )}

            {/* Error states */}
            {(pollDetailsError || pollStatusError) && (
              <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4 mb-4">
                <p className="text-red-200 text-center">
                  Error loading poll: {(pollDetailsError as Error)?.message || (pollStatusError as Error)?.message}
                </p>
              </div>
            )}

            {/* Poll Details Content */}
            {pollDetails && !pollDetailsLoading && !pollDetailsError && (
              <div className="space-y-4">
                {/* Poll Title */}
                <div className="bg-purple-500/20 border border-purple-500/50 rounded-lg p-4">
                  <h4 className="text-sm font-medium text-purple-200 mb-1">Poll Title</h4>
                  <p className="text-white text-lg font-semibold">{pollDetails[0]}</p>
                </div>

                {/* Poll Status */}
                <div className={`border rounded-lg p-4 ${
                  isPollOpen 
                    ? 'bg-green-500/20 border-green-500/50' 
                    : 'bg-red-500/20 border-red-500/50'
                }`}>
                  <h4 className={`text-sm font-medium mb-1 ${
                    isPollOpen ? 'text-green-200' : 'text-red-200'
                  }`}>
                    Status
                  </h4>
                  <p className="text-white text-lg font-semibold">
                    {isPollOpen ? '🟢 Open' : '🔴 Closed'}
                  </p>
                </div>

                {/* Poll Deadline */}
                <div className="bg-orange-500/20 border border-orange-500/50 rounded-lg p-4">
                  <h4 className="text-sm font-medium text-orange-200 mb-1">Deadline</h4>
                  <p className="text-white text-lg font-semibold">
                    {new Date(Number(pollDetails[2]) * 1000).toLocaleString()}
                  </p>
                  <p className="text-orange-200 text-sm mt-1">
                    ({isPollOpen 
                      ? `Expires in ${Math.max(0, Math.ceil((Number(pollDetails[2]) * 1000 - Date.now()) / (1000 * 60 * 60 * 24)))} days`
                      : 'Expired'
                    })
                  </p>
                </div>

                {/* Available Options */}
                <div className="bg-blue-500/20 border border-blue-500/50 rounded-lg p-4">
                  <h4 className="text-sm font-medium text-blue-200 mb-3">Available Options</h4>
                  <div className="space-y-2">
                    {pollDetails[1].map((option: string, index: number) => (
                      <div 
                        key={index}
                        className="bg-white/10 rounded-md p-3 border border-white/20"
                      >
                        <div className="flex items-center gap-3">
                          <span className="bg-blue-500 text-white text-sm px-2 py-1 rounded-full font-medium">
                            {index + 1}
                          </span>
                          <span className="text-white font-medium">{option}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* No Poll Found */}
            {!pollDetails && !pollDetailsLoading && !pollDetailsError && pollId !== '0' && (
              <div className="bg-yellow-500/20 border border-yellow-500/50 rounded-lg p-6 text-center">
                <div className="text-4xl mb-4">🔍</div>
                <h4 className="text-lg font-semibold text-yellow-200 mb-2">Poll Not Found</h4>
                <p className="text-yellow-100">
                  No poll exists with ID {pollId}. Please check the poll ID and try again.
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

