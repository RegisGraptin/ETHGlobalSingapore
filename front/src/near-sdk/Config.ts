

import { Bitcoin as Bitcoin } from "../services/bitcoin";
import { Ethereum } from "../services/ethereum";

const Sepolia = 11155111;

interface IChainConfig {
    btc: Bitcoin,
    eth: Ethereum,
}

class Config {
 
    private config: IChainConfig;
    private environment: string;
    private wallet;
    
    constructor (
        environment: string = "testnet",
        wallet
    ) {
        this.environment = environment;
        this.config = {
            "btc": new Bitcoin('https://blockstream.info/testnet/api', environment),
            "eth": new Ethereum('https://rpc2.sepolia.org', Sepolia),
        }
        this.wallet = wallet;
    }

    

}