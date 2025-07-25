import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
  sepolia,
  anvil,
  polygon,
} from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'Decentralized Voting System',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '',
  chains: [sepolia, anvil, polygon],
  ssr: true, // If your dApp uses server side rendering (SSR)
});