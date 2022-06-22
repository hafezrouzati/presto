import ID "idgenerator";
import B "mo:base/Buffer";
import T "Types";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";

import LedgerTypes "./ledgertypes";

module {

    let LEDGER = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : actor { 
        account_balance : shared query LedgerTypes.AccountBalanceArgs -> async LedgerTypes.Tokens;
        archives : shared query () -> async LedgerTypes.Archives;
        decimals : shared query () -> async { decimals : Nat32 };
        name : shared query () -> async { name : Text };
        query_blocks : shared query LedgerTypes.GetBlocksArgs -> async LedgerTypes.QueryBlocksResponse;
        symbol : shared query () -> async { symbol : Text };
        transfer : shared LedgerTypes.TransferArgs -> async LedgerTypes.TransferResult;
        transfer_fee : shared query LedgerTypes.TransferFeeArg -> async LedgerTypes.TransferFee;
    };

    public let ledger = func(): Principal { Principal.fromActor(LEDGER) };

    public class Escrow(inTrustee : Principal, inAmount : Nat64) {

        var escrowID : Text = ID.IDGenerator().getUUID();
        var buyer   : ?Principal = null;
        var seller  : ?Principal = null;
        var lender  : ?Principal = null;
        var trustee : ?Principal = ?inTrustee;

        // expected amount of the escrow in e8s
        var amount  : Nat64      = inAmount;

        var unlockTime : ?Time.Time    = null;

        var escrowEvents : B.Buffer<T.EscrowEvent> = B.Buffer<T.EscrowEvent>(20);

        private func init()
        {
            
        };

        init();

        public func getEscrowID() : async Text {
            return escrowID;
        };

        public func setBuyer(inBuyer : Principal)
        {
            buyer := ?inBuyer;
        };

        public func getBuyer() : ?Principal
        {
            return buyer;
        };

        public func setSeller(inSeller : Principal)
        {
            seller := ?inSeller
        };

        public func getSeller() : ?Principal
        {
            return seller;
        };

        public func setLender(inLender : Principal)
        {
            lender := ?inLender;
        };

        public func setTrustee(trusteeID : Text)
        {
            //trusteeUserID := trusteeID;
        };

        public func getTrustee() : ?Principal
        {
            return trustee;
        };

        public func setAmount(inAmount : Nat64)
        {
            amount := inAmount;
        };

        public func getAmount() : Nat64
        {
            return amount;
        };

        public func getEscrowEvents() : async [T.EscrowEvent]
        {
            return escrowEvents.toArray();
        };

        public func setUnlockTime(inTime : Time.Time)
        {
            unlockTime := ?inTime;
        };

        public func addEscrowEvent(inEscrowEvent : T.EscrowEvent)
        {
            escrowEvents.add(inEscrowEvent);
        };

        public func approveEvent(inEventIndex : Nat, inPrincipal : Principal) : async T.EscrowEvent
        {
            var escrowEvent : T.EscrowEvent = escrowEvents.get(inEventIndex);

            var buyerApproval   : Bool      = escrowEvent.buyerApproved;
            var sellerApproval  : Bool      = escrowEvent.sellerApproved;
            var lenderApproval  : Bool      = escrowEvent.lenderApproved;
            var trusteeApproval : Bool      = escrowEvent.trusteeApproved;

            if (?inPrincipal == buyer )
            {
                buyerApproval := true;
            } else if (?inPrincipal == seller)
            {
                sellerApproval := true;
            } else if (?inPrincipal == lender)
            {
                lenderApproval := true;
            } else if (?inPrincipal == trustee)
            {
                trusteeApproval := true;
            };

            let updatedEscrowEvent : T.EscrowEvent = {
                datetime        : Time.Time = escrowEvent.datetime;
                name            : Text      = escrowEvent.name;
                description     : Text      = escrowEvent.description;
                eventType       : Text      = escrowEvent.eventType;
                assetID         : Text      = escrowEvent.assetID;
                needsApproval   : Bool      = escrowEvent.needsApproval;
                isTitleDocument : Bool      = escrowEvent.isTitleDocument;
                isDeposit       : Bool      = escrowEvent.isDeposit;
                buyerApproved   : Bool      = buyerApproval;
                sellerApproved  : Bool      = sellerApproval;
                lenderApproved  : Bool      = lenderApproval;
                trusteeApproved : Bool      = trusteeApproval;
            };

            escrowEvents.put(inEventIndex, updatedEscrowEvent);

            return updatedEscrowEvent;

        };

        public func checkAllApproved() : async Bool
        {
            var allApproved = true;

            for (event in escrowEvents.vals())
            {
                if ((event.buyerApproved == false) or (event.sellerApproved == false) or (event.trusteeApproved == false))
                {
                    allApproved := false;
                };
            };

            return allApproved;

        };

        public func getEscrowState() : async T.EscrowType
        {
            let escrowState : T.EscrowType = {
                amount = amount;
                buyer = buyer;
                seller = seller;
                lender = lender;
                trustee = trustee;
                escrowEvents = escrowEvents.toArray();
            };

            return escrowState;
        }

    };
};
