import { NearContext } from './context';

import { useEffect, useState } from "react";
import Navbar from "./components/Navbar"
import { Wallet } from "./services/near-wallet";
import { EthereumView } from "./components/Ethereum/Ethereum";
import { BitcoinView } from "./components/Bitcoin";

import { CryptoTable } from './components/CryptoTable';


// CONSTANTS
const MPC_CONTRACT = 'v1.signer-prod.testnet';

// NEAR WALLET
const wallet = new Wallet({ network: 'testnet' });

// parse transactionHashes from URL
const txHash = new URLSearchParams(window.location.search).get('transactionHashes');
const transactions = txHash ? txHash.split(',') : [];

function App() {
  const [signedAccountId, setSignedAccountId] = useState('');
  const [status, setStatus] = useState("Please login to request a signature");
  const [chain, setChain] = useState('eth');

  useEffect(() => { wallet.startUp(setSignedAccountId) }, []);

  return (
    <NearContext.Provider value={{ wallet, signedAccountId }}>
    
      <Navbar />
      <div className="container">
        <h4>Portfolio Manager </h4>
        <p className="small">
          Safely control accounts on other chains through the NEAR MPC service. Learn more in the <a href="https://docs.near.org/abstraction/chain-signatures"> <b>documentation</b></a>.
        </p>

        <CryptoTable />

        <div className="mt-3 small text-center">
          {status}
        </div>
      </div>
    </NearContext.Provider>
  )
}

export default App
