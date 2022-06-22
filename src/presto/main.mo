
import Hash "mo:base/Hash";
import H "mo:base/HashMap";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Time "mo:base/Time";

import Account "./Account";
import B "book";
//import Ledger "canister:ledger";

import ID "idgenerator";

import UUID "mo:uuid/UUID";
import Source "mo:uuid/Source";
import AsyncSource "mo:uuid/async/SourceV4";
import XorShift "mo:rand/XorShift";

import T "Types";

import Ledger "Ledger";

import Escrow "Escrow";

actor class Presto() = this {

    private let ledger  : Ledger.Interface  = actor(Ledger.CANISTER_ID);

    let icp_fee: Nat = 10_000;
    // User balance datastructure
    private var book = B.Book();
    private stable var book_stable : [var (Principal, [(T.Token, Nat)])] = [var];

    private var escrowsMap : H.HashMap<Text, Escrow.Escrow> = H.HashMap<Text, Escrow.Escrow>(10, Text.equal, Text.hash);
    var userEscrowsMap : H.HashMap<Principal, Buffer.Buffer<Text>> = H.HashMap<Principal, Buffer.Buffer<Text>>(10, Principal.equal, Principal.hash);

    private var nextChunkID: Nat = 0;
    var chunks: H.HashMap<Nat, T.Chunk> = H.HashMap<Nat, T.Chunk>(0, Nat.equal, Hash.hash);
    var assets : H.HashMap<Text, T.Asset> = H.HashMap<Text, T.Asset>(100, Text.equal, Text.hash);

    public func greet(name : Text) : async Text {
      return "Hello, " # name # "!";
    };

    public func createEscrow(trustee : Principal, inAmount : Nat) : async Text {
      let amount = Nat64.fromNat(inAmount);
      let escrow = Escrow.Escrow(trustee, amount);  
      let escrowID = await escrow.getEscrowID();
      escrowsMap.put(escrowID, escrow);
      var userEscrowsArray : ?Buffer.Buffer<Text> = userEscrowsMap.get(trustee);
      switch (userEscrowsArray) {
        case (?userEscrowsArray)
        {
            userEscrowsArray.add(escrowID);
        };
      
        case (null) {
          var userEscrows : Buffer.Buffer<Text> = Buffer.Buffer<Text>(10);
          userEscrows.add(escrowID);
          userEscrowsMap.put(trustee, userEscrows);
        };
      };
      
      return escrowID;
    };

    public func getEscrowsForUser(user : Principal) : async [Text] {
      var userEscrows : Buffer.Buffer<Text> = Buffer.Buffer<Text>(1);
      var userEscrowsArray = userEscrowsMap.get(user);
      switch(userEscrowsArray) {
        case (?userEscrowsArray) {
          userEscrows := userEscrowsArray;
        };
        case(null) {
          userEscrows := Buffer.Buffer<Text>(1);
        };
      };
    
      return userEscrows.toArray();
    };



    // public query func getEscrowEvents(inEscrowID : Text) : async [T.EscrowEvent]
    // {
    //     let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
    //     switch(escrow)
    //     {
    //       case(?escrow) {
    //         let escrowEvents = await escrow.getEscrowEvents();
    //         return escrowEvents;
    //       };
    //       case (null) {
    //         let escrowEvent : ?T.EscrowEvent = null;
    //         return [escrowEvent];
    //       };
    //     };
    // };

    // public shared query (msg) func getEscrow(inEscrowID : Text) : async T.EscrowTest 
    // {
    //   //let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
    //   //return Option.get<Escrow.Escrow>(escrow, Escrow.Escrow(msg.caller));
    //   let theID = "TEST";
    //   let escrow : T.EscrowTest = {
    //     escrowID = theID;
    //   };
    //   return escrow;
    //   // switch(escrow)
    //   // {
    //   //   case(?escrow) {
    //   //     return Option.get<Escrow.Escrow>(?escrow, Escrow.Escrow());
    //   //   };
    //   //   case(null) {
    //   //     return Escrow.Escrow();
    //   //   };
    //   // };
    // };

    public shared (msg) func getEscrowState(inEscrowID : Text) : async T.EscrowType
    {
        let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
      //return Option.get<Escrow.Escrow>(escrow, Escrow.Escrow(msg.caller));

      switch(escrow)
      {
        case(?escrow) {
          let escrowState : T.EscrowType = await escrow.getEscrowState();
          return escrowState;
        };
        case(null) {
          let escrowState : T.EscrowType = {
            buyer = null;
            seller = null;
            trustee = null;
            lender = null;
            amount = 0;
            escrowEvents : [T.EscrowEvent] = [];
          };
          return escrowState;
        };
      };

    };

    public shared(msg) func setEscrowUnlockTime(inEscrowID : Text, inTime : Time.Time)
    {
        let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
        switch(escrow)
        {
            case(?escrow) {
                escrow.setUnlockTime(inTime)
            };

            case(null) {
            };
        };
    };

    public shared (msg) func addEscrowEvent(inEscrowID : Text, inEscrowEvent : T.EscrowEvent)
    {
        let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
        switch(escrow)
        {
            case(?escrow) {
                let escrowEvent : T.EscrowEvent = {
                    datetime        : Time.Time = Time.now();
                    name            : Text      = inEscrowEvent.name;
                    description     : Text      = inEscrowEvent.description;
                    eventType       : Text      = inEscrowEvent.eventType;
                    assetID         : Text      = inEscrowEvent.assetID;
                    needsApproval   : Bool      = inEscrowEvent.needsApproval;
                    isTitleDocument : Bool      = inEscrowEvent.isTitleDocument;
                    isDeposit       : Bool      = inEscrowEvent.isDeposit;
                    buyerApproved   : Bool      = false;
                    sellerApproved  : Bool      = false;
                    lenderApproved  : Bool      = false;
                    trusteeApproved : Bool      = false;
                };

                escrow.addEscrowEvent(escrowEvent);
            };

            case(null) {

            };
          
        };
    };

    public shared(msg) func approveEscrowEvent(inEscrowID : Text, inEscrowEventIndex : Nat, inUserPrincipal : Principal) : async T.EscrowEvent
    {
        let principal = msg.caller;
        let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
        switch(escrow)
        {
            case(?escrow) {
              let escrowEvent: T.EscrowEvent = await escrow.approveEvent(inEscrowEventIndex, inUserPrincipal);
              return escrowEvent;
            };
            
            case(null) {
                let nullEvent : T.EscrowEvent = {
                    datetime        : Time.Time = Time.now();
                    name            : Text      = "null";
                    description     : Text      = "null";
                    eventType       : Text      = "null";
                    assetID         : Text      = "null";
                    needsApproval   : Bool      = false;
                    isTitleDocument : Bool      = false;
                    isDeposit       : Bool      = false;
                    buyerApproved   : Bool      = false;
                    sellerApproved  : Bool      = false;
                    lenderApproved  : Bool      = false;
                    trusteeApproved : Bool      = false;
                };
                return nullEvent;  
            };
        };
    };

    public shared (msg) func setBuyer(inEscrowID : Text, inBuyerPrincipal : Principal)
    {
        let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
        switch(escrow)
        {
            case(?escrow) {
              escrow.setBuyer(inBuyerPrincipal);
            };
            
            case(null) {

            };
        };
    };

    public shared (msg) func setSeller(inEscrowID : Text, inSellerPrincipal : Principal)
    {
        let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
        switch(escrow)
        {
            case(?escrow) {
              escrow.setSeller(inSellerPrincipal);
            };
            
            case(null) {

            };
        };
    };


    ///====== Upload functions ========//////
    public func getDocumentID() : async Text
    {
        return ID.IDGenerator().getUUID();
    };

    public func getAsset(assetID : Text) : async ?[Nat8]
    {
        let key: Text = "/assets/" # assetID;
        let asset: ?T.Asset = assets.get(key);
        switch (asset) {
              case(?{content_type: Text; encoding: T.SimpleAssetEncoding;}) 
              {
                  return ?encoding.content;
              };
              case null {
                  return null;
              };
        };
    };

    public shared query({caller}) func http_request(request: T.HttpRequest,) : async T.HttpResponse
    {
        if (request.method == "GET")
        {
          let split: Iter.Iter<Text> = Text.split(request.url, #char '?');
          let key: Text = Iter.toArray(split)[0];

          let asset: ?T.Asset = assets.get(key);

          switch (asset) {
              case(?{content_type: Text; encoding: T.SimpleAssetEncoding;}) 
              {
                  return {
                      body = encoding.content;
                      headers = [ ("Content-Type", content_type),
                                  ("accept-ranges", "bytes"),
                                  ("cache-control", "private, max-age=0") ];
                      status_code = 200;
                      // streaming_strategy = create_strategy(
                      //     key, 0, {content_type; encoding;}, encoding,
                      // );
                  };
              };
              case null {

              };
          };
        };

        return {
          body = Blob.toArray(Text.encodeUtf8("Permission denied. Could not perform this operation"));
          headers = [];
          status_code = 403;
          streaming_strategy = null;
        };
    };

    // private func create_strategy(key : Text, index : Nat, asset : T.Asset, encoding : T.AssetEncoding ) : ?T.StreamingStrategy
    // {
    //     switch (create_token(key, index, encoding)) 
    //     {
    //         case (null) { null };
    //         case (? token) {
    //             let self: Principal = Principal.fromActor(this);
    //             let canisterId: Text = Principal.toText(self);
    //             let canister = actor(canisterId) : actor { http_request_streaming_callback : shared () -> async () };

    //             return ?#Callback({
    //                 token;
    //                 callback = canister.http_request_streaming_callback;
    //             });
    //         };
    //     };
    // };

    // public shared query({caller}) func http_request_streaming_callback( st : T.StreamingCallbackToken,) : async T.StreamingCallbackHttpResponse
    // {
    //     switch(assets.get(st.key))
    //     {
    //         case(null) throw Error.reject("key not found: " # st.key);
    //         case (? asset)
    //         {
    //             return {
    //                 token = create_token(
    //                     st.key,
    //                     st.index,
    //                     asset.encoding,
    //                 );
    //                 body = asset.encoding.content_chunks[st.index];
    //             };
    //         };
    //     };
    // };

    private func create_token(key : Text, chunk_index : Nat, encoding : T.AssetEncoding) : ?T.StreamingCallbackToken
    {
        if(chunk_index + 1 >= encoding.content_chunks.size()) {
            null;
        } else {
            ?{
                key;
                index = chunk_index + 1;
                content_encoding = "gzip";
            };
        };
    };

    public shared({caller}) func upload_file(file : T.File)
    {
        let simpleEncoding : T.SimpleAssetEncoding = {
            modified            = Time.now();
            content             = file.content;
            total_length        = file.contentLength;
            certified           = false;
        };

        let asset : T.Asset = {
            encoding = simpleEncoding;
            content_type = file.content_type;
          };

        assets.put(Text.concat("/assets/", file.assetID), asset);
    };

    public shared({caller}) func create_chunk(chunk: T.Chunk) : async { chunk_id : Nat }
    {
        nextChunkID := nextChunkID + 1;
        chunks.put(nextChunkID, chunk);
        return {chunk_id = nextChunkID};
    };

    // public shared({caller}) func commit_batch({batch_name: Text; chunk_ids: [Nat]; content_type: Text;} : {
    //     batch_name: Text;
    //     content_type: Text;
    //     chunk_ids: [Nat];
    // },) : async () 
    // {
    //     var content_chunks : [[Nat8]] = [];
    //     for (chunk_id in chunk_ids.vals())
    //     {
    //         let chunk: ?T.Chunk = chunks.get(chunk_id);

    //         switch(chunk)
    //         {
    //             case(?{content})
    //             {
    //                 content_chunks := Array.append<[Nat8]>(content_chunks, [content]);
    //             };
    //             case null {

    //             };
    //         };
    //     };

    //     if (content_chunks.size() > 0)
    //     {
    //         var total_length = 0;
    //         for (chunk in content_chunks.vals()) total_length += chunk.size();

    //         assets.put(Text.concat("/assets/", batch_name),
    //         {
    //             content_type = content_type;
    //             encoding = 
    //             {
    //                 modified = Time.now();
    //                 content_chunks;
    //                 certified = false;
    //                 total_length
    //             };
    //         });
    //     };
    // };






    // ===== DEPOSIT FUNCTIONS =====
    // Return the account ID specific to this user's subaccount
    public shared(msg) func getDepositAddress(): async Blob {
        Account.accountIdentifier(Principal.fromActor(this), Account.principalToSubaccount(msg.caller));
    };

    public shared(msg) func getDepositAddressString() : async ?Text {
      let accountID = Account.accountIdentifier(Principal.fromActor(this), Account.principalToSubaccount(msg.caller));
      return Text.decodeUtf8(accountID);
    };

    public shared(msg) func deposit(token: T.Token): async T.DepositReceipt {
        //let ledgerPrincipal = Principal.fromActor(ledger);
        //Debug.print("Depositing Token: " # Principal.toText(token) # " LEDGER: " # Principal.toText(ledgerPrincipal));
        //if (token == ledger) {
            await depositIcp(msg.caller)
        //} else {
        //   await depositDip(msg.caller, token)
        //}
    };

    // After user approves tokens to the DEX
    private func depositDip(caller: Principal, token: T.Token): async T.DepositReceipt {
        // cast token to actor
        let dip20 = actor (Principal.toText(token)) : T.DIPInterface;

        // get DIP fee
        let dip_fee = await fetch_dip_fee(token);

        // Check DIP20 allowance for DEX
        let balance : Nat = (await dip20.allowance(caller, Principal.fromActor(this)));

        // Transfer to account.
        let token_reciept = if (balance > dip_fee) {
            await dip20.transferFrom(caller, Principal.fromActor(this),balance - dip_fee);
        } else {
            return #Err(#BalanceLow);
        };

        switch token_reciept {
            case (#Err e) {
                return #Err(#TransferFailure);
            };
            case _ {};
        };
        let available = balance - dip_fee;

        // add transferred amount to user balance
        book.addTokens(caller,token,available);

        // Return result
        #Ok(available)
    };

    // After user transfers ICP to the target subaccount
    private func depositIcp(caller: Principal): async T.DepositReceipt {

        // Calculate target subaccount
        // NOTE: Should this be hashed first instead?
        let source_account = Account.accountIdentifier(Principal.fromActor(this), Account.principalToSubaccount(caller));

        // Check ledger for value
        let balance = await ledger.account_balance({ account = source_account });

        // Transfer to default subaccount
        let icp_receipt = if (Nat64.toNat(balance.e8s) > icp_fee) {
            //OLD
            await ledger.transfer({
                memo: Nat64    = 0;
                from_subaccount = ?Account.principalToSubaccount(caller);
                to = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
                amount = { e8s = balance.e8s - Nat64.fromNat(icp_fee)};
                fee = { e8s = Nat64.fromNat(icp_fee) };
                created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
            })

        } else {
            return #Err(#BalanceLow);
        };

        switch icp_receipt {
            case ( #Err _) {
                return #Err(#TransferFailure);
            };
            case _ {};
        };
        let available = { e8s : Nat = Nat64.toNat(balance.e8s) - icp_fee };

        // keep track of deposited ICP
        book.addTokens(caller,Principal.fromActor(ledger),available.e8s);

        // Return result
        #Ok(available.e8s)
    };


    // ===== WITHDRAW FUNCTIONS =====
    public shared(msg) func withdraw(token: T.Token, amount: Nat, address: Principal) : async T.WithdrawReceipt {
        //if (token == ledger) {
            let account_id = Account.accountIdentifier(address, Account.defaultSubaccount());
            await withdrawIcp(msg.caller, amount, account_id)
        //} else {
        //    await withdrawDip(msg.caller, token, amount, address)
        //}
    };

    private func withdrawIcp(caller: Principal, amount: Nat, account_id: Blob) : async T.WithdrawReceipt {
        Debug.print("Withdraw...");
        let ledgerPrincipal = Principal.fromActor(ledger);

        // remove withdrawal amount from book
        switch (book.removeTokens(caller, ledgerPrincipal, amount+icp_fee)){
            case(null){
                return #Err(#BalanceLow)
            };
            case _ {};
        };

        // Transfer amount back to user
        let icp_reciept =  await ledger.transfer({
            memo: Nat64    = 0;
            from_subaccount = ?Account.defaultSubaccount();
            to = account_id;
            amount = { e8s = Nat64.fromNat(amount + icp_fee) };
            fee = { e8s = Nat64.fromNat(icp_fee) };
            created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
        });

        switch icp_reciept {
            case (#Err e) {
                // add tokens back to user account balance
                
                book.addTokens(caller,ledgerPrincipal,amount+icp_fee);
                return #Err(#TransferFailure);
            };
            case _ {};
        };
        #Ok(amount)
    };

    private func withdrawDip(caller: Principal, token: T.Token, amount: Nat, address: Principal) : async T.WithdrawReceipt {

        // cast canisterID to token interface
        let dip20 = actor (Principal.toText(token)) : T.DIPInterface;

        // get dip20 fee
        let dip_fee = await fetch_dip_fee(token);

        // remove withdrawal amount from book
        switch (book.removeTokens(caller,token,amount+dip_fee)){
            case(null){
                return #Err(#BalanceLow)
            };
            case _ {};
        };

        // Transfer amount back to user
        let txReceipt =  await dip20.transfer(address, amount);

        switch txReceipt {
            case (#Err e) {
                // add tokens back to user account balance
                book.addTokens(caller,token,amount + dip_fee);
                return #Err(#TransferFailure);
            };
            case _ {};
        };
        return #Ok(amount)
    };


    // ===== Transfer Functions ========

    public shared(msg) func releaseToSeller(inEscrowID : Text) : async T.WithdrawReceipt {

      let escrow : ?Escrow.Escrow = escrowsMap.get(inEscrowID);
      var escrowAmount : Nat64 = 0;

      switch(escrow)
      {
        case(?escrow) {
            var escrowEventsApproved : Bool = await escrow.checkAllApproved();
            if (escrowEventsApproved == true)
            {
                let buyerPrincipal :?Principal = escrow.getBuyer();
                var sellerPrincipal : ?Principal = escrow.getSeller();
                
                escrowAmount        := escrow.getAmount();

                if (sellerPrincipal != null)
                {
                    if (buyerPrincipal != null)
                    {
                        let sellerPrincipalUnwrap : Principal = Option.get<Principal>(sellerPrincipal, Principal.fromActor(ledger));
                        let buyerPrincipalUnwrap : Principal = Option.get<Principal>(buyerPrincipal, Principal.fromActor(ledger));

                        let sellerAccountID = Account.accountIdentifier(sellerPrincipalUnwrap, Account.defaultSubaccount());

                        Debug.print("Withdraw...");
                        let ledgerPrincipal = Principal.fromActor(ledger);

                        let escrowOut = { e8s : Nat = Nat64.toNat(escrowAmount) };

                        // remove withdrawal amount from book
                        switch (book.removeTokens(buyerPrincipalUnwrap, ledgerPrincipal, escrowOut.e8s+icp_fee)){
                            case(null){
                                return #Err(#BalanceLow)
                            };
                            case _ {};
                        };

                        // Transfer amount to seller's account
                        let icp_reciept =  await ledger.transfer({
                            memo: Nat64    = 0;
                            from_subaccount = ?Account.defaultSubaccount();
                            to = sellerAccountID;
                            amount = { e8s = Nat64.fromNat(escrowOut.e8s + icp_fee) };
                            fee = { e8s = Nat64.fromNat(icp_fee) };
                            created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
                        });

                        switch icp_reciept {
                            case (#Err e) {
                                // add tokens back to user account balance
                                book.addTokens(buyerPrincipalUnwrap,ledgerPrincipal,escrowOut.e8s+icp_fee);
                                return #Err(#TransferFailure);
                            };
                            case _ {};
                        };

                        return #Ok(escrowOut.e8s);
                    };
                };
            };

            return #Err(#TransferFailure);
        };

        case(null) {
          return #Err(#TransferFailure);
        };
      };
    };

    public shared(msg) func getBalanceForUser() : async Nat {
      let userEntry = book.get(msg.caller);
      switch(?userEntry) {
          case(?userEntry) 
          {
            let userEntryUnwrap = Option.get<H.HashMap<T.Token, Nat>>(userEntry, H.HashMap<T.Token, Nat>(1, Principal.equal, Principal.hash));
            let userBalance = userEntryUnwrap.get(Principal.fromActor(ledger));
            let userBalanceUnwrap = Option.get<Nat>(userBalance, 1111);
            return userBalanceUnwrap;
          };
          case(null) {
            return 2222;
          };
      };
    };

    // ===== INTERNAL FUNCTIONS =====
    private func fetch_dip_fee(token: T.Token) : async Nat {
        let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
        let metadata = await dip20.getMetadata();
        metadata.fee
    };




    // UPGRADE functions
    system func preupgrade() {
        book_stable := Array.init(book.size(), (Principal.fromText("123456"), []));
        var i = 0;
        for ((x, y) in book.entries()) {
            book_stable[i] := (x, Iter.toArray(y.entries()));
            i += 1;
        };
        //orders_stable := getAllOrders();
    };

    // After canister upgrade book map gets reconstructed from stable array
    system func postupgrade() {
        // Reload book.
        for ((key: Principal, value: [(T.Token, Nat)]) in book_stable.vals()) {
            let tmp: H.HashMap<T.Token, Nat> = H.fromIter<T.Token, Nat>(Iter.fromArray<(T.Token, Nat)>(value), 10, Principal.equal, Principal.hash);
            book.put(key, tmp);
        };

        // // TODO Reload exchanges (find solution for async symbol retrieving).
        // for(o in orders_stable.vals()) {
        //     let trading_pair = switch (create_trading_pair(o.from,o.to)){
        //         // should not occur here since all orders already validated
        //         case null (o.from,o.to);
        //         case (?tp) tp;
        //     };
        //     let exchange = switch (exchanges.get(trading_pair)) {
        //         case null {
        //             let exchange : E.Exchange = E.Exchange(trading_pair, book);
        //             exchanges.put(trading_pair,exchange);
        //             exchange
        //         };
        //         case (?e) e
        //     };
        //     exchange.addOrder(o);
        // };

        // Clean stable memory.
        book_stable := [var];
        // orders_stable := [];
    };

};
