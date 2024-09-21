
import { deriveChildPublicKey, najPublicKeyStrToUncompressedHexPoint, uncompressedHexPointToBtcAddress } from '../../services/kdf';

class BTCOperation implements ChainOperation {
    
    async createNewWallet() {

        const { address, publicKey } = await BTC.deriveAddress(signedAccountId, derivationPath);


        
    }

    async deriveAddress(accountId, derivation_path) {
        const publicKey = await deriveChildPublicKey(najPublicKeyStrToUncompressedHexPoint(), accountId, derivation_path);
        const address = await uncompressedHexPointToBtcAddress(publicKey, this.network);
        return { publicKey: Buffer.from(publicKey, 'hex'), address };
    }
    
}