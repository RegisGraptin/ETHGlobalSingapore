

interface ChainOperation {
    // Interface allowing common operation
    
    
    // Create a new wallet
    createNewWallet();

    sendAmount(receiver, amount);

    relayTransaction();
}