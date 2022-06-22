import Bool "mo:base/Bool";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import B "mo:base/Buffer";
import Blob "mo:base/Blob";
import A "mo:base/Array";
import P "mo:base/Principal";

module {
    public type EscrowType = {
        buyer           : ?P.Principal;
        seller          : ?P.Principal;
        lender          : ?P.Principal;
        trustee         : ?P.Principal;
        amount          : Nat64;
        escrowEvents    : [EscrowEvent]
    };

    public type EscrowEvent =
    {
        name                : Text;
        description         : Text;
        datetime            : Time.Time;
        eventType           : Text;
        assetID             : Text;
        needsApproval       : Bool;
        isTitleDocument     : Bool;
        isDeposit           : Bool;
        buyerApproved       : Bool;
        sellerApproved      : Bool;
        lenderApproved      : Bool;
        trusteeApproved     : Bool;
    };

    public type EscrowDocument =
    {
        documentID      : Text;
        asset           : Asset;
        isTitleDocument : Bool;
    };

    public type EscrowTest =
    {
        escrowID : Text;
    };

    
    // ledger types
    public type Token = Principal;

    public type DIPInterface = actor {
        transfer : (Principal,Nat) ->  async TxReceipt;
        transferFrom : (Principal,Principal,Nat) -> async TxReceipt;
        allowance : (owner: Principal, spender: Principal) -> async Nat;
        getMetadata: () -> async Metadata;
    };

    // Dip20 token interface
    public type TxReceipt = {
        #Ok: Nat;
        #Err: {
            #InsufficientAllowance;
            #InsufficientBalance;
            #ErrorOperationStyle;
            #Unauthorized;
            #LedgerTrap;
            #ErrorTo;
            #Other;
            #BlockUsed;
            #AmountTooSmall;
        };
    };

    public type Metadata = {
        logo : Text; // base64 encoded logo or logo url
        name : Text; // token name
        symbol : Text; // token symbol
        decimals : Nat8; // token decimal
        totalSupply : Nat; // token total supply
        owner : Principal; // token owner
        fee : Nat; // fee for update calls
    };

    public type WithdrawErr = {
        #BalanceLow;
        #TransferFailure;
    };
    public type WithdrawReceipt = {
        #Ok: Nat;
        #Err: WithdrawErr;  
    };
    public type DepositErr = {
        #BalanceLow;
        #TransferFailure;
    };
    public type DepositReceipt = {
        #Ok: Nat;
        #Err: DepositErr;
    };
    public type Balance = {
        owner: Principal;
        token: Token;
        amount: Nat;
    };


    //==== Asset Types =======//
    public type HeaderField = (Text, Text);
    public type Key = Text;

    public type File = {
        assetID : Text;
        content: [Nat8];
        contentLength: Nat;
        content_type : Text;
    };

    public type Chunk = {
        batch_name : Text;
        content : [Nat8];
    };

    public type Asset = {
        encoding: SimpleAssetEncoding;
        content_type: Text;
    };

    public type SimpleAssetEncoding = {
        modified            : Int;
        content             : [Nat8];
        total_length        : Nat;
        certified           : Bool;
    };

    public type AssetEncoding = {
        modified            : Int;
        content_chunks      : [[Nat8]];
        total_length        : Nat;
        certified           : Bool;  
    };

    public type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };

    public type HttpResponse = {
        body : [Nat8];
        headers : [HeaderField];
        status_code : Nat16;
        //streaming_strategy : ?StreamingStrategy;
    };

    public type StreamingCallbackHttpResponse = {
        body: [Nat8];
        token: ?StreamingCallbackToken;
    };

    public type StreamingCallbackToken = {
        key: Key;
        content_encoding: Text;
        index: Nat;
        //sha256: Blob;
    };

    public type StreamingStrategy = Callback;

    public type Callback = {
        callback: shared query (StreamingCallbackToken) -> async (?StreamingCallbackHttpResponse);
        token: StreamingCallbackToken;
    }

    // type StreamingStrategy = variant {
    // Callback: record {
    //     callback: func (StreamingCallbackToken) -> (opt StreamingCallbackHttpResponse) query;
    //     token: StreamingCallbackToken;
    // };
    // };

//     // AccountIdentifier is a 32-byte array.
// // The first 4 bytes is big-endian encoding of a CRC32 checksum of the last 28 bytes.
// type AccountIdentifier = blob;

// // Subaccount is an arbitrary 32-byte byte array.
// // Ledger uses subaccounts to compute the source address, which enables one
// // principal to control multiple ledger accounts.
// type SubAccount = blob;


//         // Arguments for the `transfer` call.
//     type TransferArgs = {
//         // Transaction memo.
//         // See comments for the `Memo` type.
//         memo: Memo;
//         // The amount that the caller wants to transfer to the destination address.
//         amount: Tokens;
//         // The amount that the caller pays for the transaction.
//         // Must be 10000 e8s.
//         fee: Tokens;
//         // The subaccount from which the caller wants to transfer funds.
//         // If null, the ledger uses the default (all zeros) subaccount to compute the source address.
//         // See comments for the `SubAccount` type.
//         from_subaccount: SubAccount;
//         // The destination account.
//         // If the transfer is successful, the balance of this address increases by `amount`.
//         to: AccountIdentifier;
//         // The point in time when the caller created this request.
//         // If null, the ledger uses current IC time as the timestamp.
//         created_at_time: TimeStamp;
//     };

//     type TransferResult = {
//         Ok : BlockIndex;
//         Err : TransferError;
//     };

//     // Arguments for the `account_balance` call.
//     type AccountBalanceArgs = {
//         account: AccountIdentifier;
//     };

//     type TransferFeeArg = {};

//     type TransferFee = {
//         // The fee to pay to perform a transfer
//         transfer_fee: Tokens;
//     };

//     type GetBlocksArgs = {
//         // The index of the first block to fetch.
//         start : BlockIndex;
//         // Max number of blocks to fetch.
//         length : nat64;
//     };    

//     type QueryBlocksResponse = {
//         // The total number of blocks in the chain.
//         // If the chain length is positive, the index of the last block is `chain_len - 1`.
//         chain_length : nat64;

//         // System certificate for the hash of the latest block in the chain.
//         // Only present if `query_blocks` is called in a non-replicated query context.
//         certificate : blob;

//         // List of blocks that were available in the ledger when it processed the call.
//         //
//         // The blocks form a contiguous range, with the first block having index
//         // [first_block_index] (see below), and the last block having index
//         // [first_block_index] + len(blocks) - 1.
//         //
//         // The block range can be an arbitrary sub-range of the originally requested range.
//         blocks : Block;

//         // The index of the first block in "blocks".
//         // If the blocks vector is empty, the exact value of this field is not specified.
//         first_block_index : BlockIndex;

//         // Encoding of instructions for fetching archived blocks whose indices fall into the
//         // requested range.
//         //
//         // For each entry `e` in [archived_blocks], `[e.from, e.from + len)` is a sub-range
//         // of the originally requested block range.
//         archived_blocks : {
//             // The index of the first archived block that can be fetched using the callback.
//             start : BlockIndex;

//             // The number of blocks that can be fetch using the callback.
//             length : nat64;

//             // The function that should be called to fetch the archived blocks.
//             // The range of the blocks accessible using this function is given by [from]
//             // and [len] fields above.
//             callback : QueryArchiveFn;
//         };
//     };    

//     type Tokens = {
//         e8s : nat64;
//     };    



};