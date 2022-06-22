<template>
    <v-dialog v-model="loading" fullscreen full-width>
    <v-container fluid fill-height style="background-color: rgba(255, 255, 255, 0.5);">
        <v-layout justify-center align-center>
        <v-progress-circular
            indeterminate
            color="primary">
        </v-progress-circular>
        </v-layout>
    </v-container>
    </v-dialog>
<div class="escrow_container">
    <p class="header_text">
        ESCROW ID: {{ escrowID }}<br/><br/>
    </p>    
    <p class="header_text">
        USER ID: {{ userID }}<br/><br/>
    </p>        

    <div v-if="userIsTrustee">
    <v-row align="center">
        <v-btn @click="addEscrowEventDialog()" color="primary">Add Escrow Event</v-btn>
    </v-row>            
    </div>    

    <div v-if="!userIsBuyer && !userIsSeller && !userIsTrustee">
        Select Your Role
        <v-btn @click="registerAsBuyer()" color="primary">Buyer</v-btn>
        <v-btn @click="registerAsSeller()" color="primary">Seller</v-btn>
    </div>

    <v-timeline align="start">
        <v-timeline-item
        v-for="(item, i) in escrowEvents"
        :key="i"
        dot-color="primary"
        :icon="item.icon"
        fill-dot
        >
        <v-card>
            <v-card-title :class="['text-h6', 'bg-purple', 'white_text']" color="primary">
            {{ item.name }}
            </v-card-title>
            <v-card-text class="white text--primary">
            <p>{{ item.description }}</p>
            <template v-if="(item.assetID != 'none')">
                <p v-if="(item.assetID != 'none')">
                    <a :href="'https://3us5k-qyaaa-aaaak-qap3a-cai.ic0.app/#/viewdocument/' + item.assetID" target="_blank">View Document</a>
                </p>
            </template>

            <p>
                <div v-if="item.isDeposit">
                    <div v-if="userIsBuyer">
                        <v-btn @click="getDepositAddress()" color="primary">Get Deposit Address</v-btn>
                        <template v-if="buyerDepositAddress">
                            <p class="address_text">Deposit Address {{ buyerDepositAddress }}</p>
                        </template>
                        <v-btn @click="deposit()" color="primary">Confirm Deposit</v-btn>
                        <!--// <v-btn @click="getBalance()" color="primary">Get Balance</v-btn> //-->
                    </div>
                </div>    
                
                <div v-if="item.isTitleDocument && item.trusteeApproved && item.buyerApproved && item.sellerApproved">
                    <div v-if="userIsTrustee">
                        <v-btn @click="releaseToSeller()" color="primary">Release Funds to Seller</v-btn>
                    </div>                        
                </div>
            </p>
            <v-btn v-if="(userIsTrustee && !item.trusteeApproved) || (userIsBuyer && !item.buyerApproved) || (userIsSeller && !item.sellerApproved)"
                color="primary"
                @click="approveEvent(i)"
            >
                Approve
            </v-btn>
            <v-btn color="blue-grey" v-if="item.buyerApproved">BUYER APPROVED</v-btn>
            <v-btn color="info" v-if="item.sellerApproved">SELLER APPROVED</v-btn>
            <v-btn color="secondary" v-if="item.trusteeApproved">TRUSTEE APPROVED</v-btn>
            </v-card-text>
        </v-card>
        </v-timeline-item>
    </v-timeline>




</div>

    <v-dialog v-model="fundsReleasedDialog" width="auto">
        <v-card width="300" elevation="24">
            <v-card-title color="primary" :class="['text-h6', 'bg-purple', 'white_text']">Disbursement</v-card-title>
            <v-card-text>
                Funds were successfully disbursed to seller.
            </v-card-text>
            <v-card-actions>
                <v-btn color="primary" @click="fundsReleasedDialog = false">Close</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="dialog" width="auto">
      <v-card width="300" height="500" elevation="24">
        <v-card-title color="primary">Add Escrow Event</v-card-title>
        <v-text-field v-model="eventName" solo color="secondary" label="Name" variant="name" placeholder="Event Name"></v-text-field>
        <v-text-field v-model="eventDescription" solo color="secondary" label="Description" variant="description" placeholder="Event Description"></v-text-field>
        <v-text-field v-model="eventType" solo color="secondary" label="Type" variant="type" placeholder="Event Type"></v-text-field>
        <v-file-input
                  accept=".pdf"
                  label="Click here to select a .pdf file"
                  outlined
                 @change="selectFile"
                >
                </v-file-input>
        <v-btn color="primary" @click="upload()">Upload File</v-btn>
        <v-checkbox v-model="eventIsDeposit" label="Is Deposit?"></v-checkbox>
        <v-checkbox v-model="eventNeedsApproval" label="Requires Approval?"></v-checkbox>
        <v-checkbox v-model="eventIsTitleDocument" label="Is Title Document?"></v-checkbox>
        
        <v-card-actions>
          <v-btn color="primary" @click="addEscrowEvent()">Add Event</v-btn>
          <v-btn color="primary" @click="dialog = false">Close Dialog</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

</template>

<script setup>
    import { inject, ref, onMounted } from 'vue';
    import { useRoute, useRouter } from 'vue-router';
    import { AccountIdentifier, LedgerCanister } from "@dfinity/nns";
    import { presto } from '../../../declarations/presto';
    
    const router = useRouter();
    const route = useRoute();   

    var userPrincipal = inject('userPrincipal');
    var userID        = ref(userPrincipal);

    const escrowID      = ref(route.params.escrowID);
    var escrowEvents    = ref([]);
    var escrowState     = ref([]);

    var userIsBuyer     = ref(false);
    var userIsSeller    = ref(false);
    var userIsTrustee   = ref(false);
    

    var loading = ref(false);

    var dialog = ref (false);
    var fundsReleasedDialog = ref (false);

    var ledger = null;

    var eventName        = ref("");
    var eventDescription = ref("");
    var eventType        = ref("");
    var eventAssetID     = ref(null);
    var eventNeedsApproval = ref(false);
    var eventIsTitleDocument = ref(false);
    var eventIsDeposit   = ref(false);

    var eventAsset = ref(null);
    var eventAsset2 = null;

    var buyerDepositAddress = ref(null);

    var approvalText = ref("Approve");

    // lifecycle hooks
    onMounted( async () => {
        ledger = LedgerCanister.create();
        
        loadEscrow();
    })

    async function on()
    {
        dialog.value = true;
    }

    async function loadEscrow() {
        loading.value = true;

        var escrowStatePresto = await presto.getEscrowState(escrowID.value);
        console.log(escrowStatePresto);

        console.log("Buyer");
        console.log(escrowStatePresto.buyer.toString());
        console.log("Seller");
        console.log(escrowStatePresto.seller.toString());
        console.log("Lender");
        console.log(escrowStatePresto.lender.toString());
        console.log("Trustee");
        console.log(escrowStatePresto.trustee.toString());

        if (escrowStatePresto.trustee.toString() == userPrincipal.value.toString())
        {
            console.log("PRESTO");
            userIsTrustee.value = true;
        }

        if (escrowStatePresto.buyer.toString() == userPrincipal.value.toString())
        {
            userIsBuyer.value = true;
        }

        if (escrowStatePresto.seller.toString() == userPrincipal.value.toString())
        {
            userIsSeller.value = true;
        }        

        var prestoEvents = escrowStatePresto.escrowEvents;
        for (var i=0;i<prestoEvents.length;i++)
        {
            var escrowEvent = prestoEvents[i];
            escrowEvent["color"] = 'light-violet';
            //escrowEvent["assetID"] = "https://3us5k-qyaaa-aaaak-qap3a-cai.ic0.app/#/viewdocument/" + escrowEvent["assetID"];
        }
        
        //escrowState.value = escrowEvents;

        escrowEvents.value = prestoEvents;

        loading.value = false;
        console.log(escrowState.value);
    }

    async function addEscrowEventDialog()
    {
        // clear form variables
        eventName.value = null;
        eventDescription.value = null;
        eventType.value = null;
        eventAssetID.value = null;
        eventNeedsApproval.value = false;
        eventIsTitleDocument.value = false;
        eventIsDeposit.value = false;

        dialog.value = true;
    };

    async function addEscrowEvent()
    {
        loading.value = true;

        if (eventAssetID.value == null)
        {
            eventAssetID.value = "none";
        }

        let escrowEvent = {
            name                : eventName.value,
            description         : eventDescription.value,
            datetime            : 0,
            eventType           : eventType.value,
            assetID             : eventAssetID.value,
            needsApproval       : eventNeedsApproval.value,
            isTitleDocument     : eventIsTitleDocument.value,
            isDeposit           : eventIsDeposit.value,
            buyerApproved       : false,
            sellerApproved      : false,
            lenderApproved      : false,
            trusteeApproved     : false
        }

        await presto.addEscrowEvent(escrowID.value, escrowEvent);

        eventAssetID.value = null;

        loading.value = false;
        dialog.value = false;
        loadEscrow();
    };

    async function approveEvent(eventIndex)
    {
        loading.value = true;
        console.log("approving event");
        var event = await presto.approveEscrowEvent(escrowID.value, eventIndex, userPrincipal.value);
        console.log(event);
        console.log("approved event");
        loading.value = false;
        loadEscrow();
    }

    function buf2hex(buffer) { // buffer is an ArrayBuffer
    return [...new Uint8Array(buffer)]
        .map(x => x.toString(16).padStart(2, '0'))
        .join('');
    }

    async function getDepositAddress()
    {
        let depositAddress = await presto.getDepositAddress();
        console.log(depositAddress);

        let accIDHex = buf2hex(depositAddress.buffer);
        console.log(accIDHex);

        buyerDepositAddress.value = accIDHex;

        let accID = AccountIdentifier.fromHex(accIDHex);

        const balance = await ledger.accountBalance({ accID });

        console.log(`Balance: ${balance.toE8s()}`);
    };

    async function deposit()
    {
        console.log("confirming deposit");
        let transactionResult = await presto.deposit(userPrincipal.value);
        console.log(transactionResult);
    };

    async function getBalance()
    {
        console.log("getting balance for user");
        let result = await presto.getBalanceForUser(userPrincipal.value);
        console.log(result);
    }

    async function registerAsBuyer()
    {
        console.log("setting user as buyer...");
        await presto.setBuyer(escrowID.value, userPrincipal.value);
        loadEscrow();
        console.log("set user as buyer.");
    };

    async function registerAsSeller()
    {
        console.log("setting user as seller...");
        await presto.setSeller(escrowID.value, userPrincipal.value);
        loadEscrow();
        console.log("set user as seller.");
    };

    async function releaseToSeller()
    {
        console.log("Attempting to release funds to seller");
        loading.value = true;
        let transactionResult = await presto.releaseToSeller(escrowID.value);
        console.log(transactionResult);
        loading.value = false;
        fundsReleasedDialog.value = true;
    };

    const uploadChunk = async ({batch_name, chunk}) => presto.create_chunk({
        batch_name,
        content: [...new Uint8Array(await chunk.arrayBuffer())]
    });

    async function selectFile(event)
    {
        eventAsset.value = event.target.files[0];
        console.log(eventAsset.value);
    }

    async function upload()
    {
        if (!eventAsset)
        {
            alert("No File selected");
            return;    
        }
        console.log("starting upload...");

        loading.value = true;

        eventAssetID.value = await presto.getDocumentID();

        console.log(eventAssetID);

        let fileReader = new FileReader();

        fileReader.readAsArrayBuffer(eventAsset.value);
        fileReader.onload = async function(ev) {
            const array = new Uint8Array(ev.target.result);

            var f = {
                content_type: "application/pdf",
                contentLength: eventAsset.value.size,
                assetID: eventAssetID.value,
                content: array
            };

            await presto.upload_file(f);

            console.log('file uploaded.');

            loading.value = false;

        }

        // const batch_name = eventAssetID;
        // const chunks = [];
        // const chunksize = 1500000;

        // for (let start = 0; start < eventAsset.size; start += chunkSize)
        // {
        //     const chunk = file.slice(start, start + chunkSize);
        //     chunks.push(uploadChunk({
        //         eventAssetID, 
        //         chunk
        //     }));
        // }

        // const chunkIds = await Promise.all(chunks);

        // console.log(chunkIds);

        // await presto.commit_batch({
        //     eventAssetID,
        //     chunk_ids: chunkIds.map(({chunk_id}) => chunk_id),
        //     content_type: eventAsset.type
        // });
    };


</script>

<style>
.escrow_container 
{
    top: 200px;
}

.bg-light-violet
{
    background-color: #CF9FFF;
}

.light-violet
{
    color: #CF9FFF;
}

.bg-purple
{
    background-color: rgb(98,0, 238);
}

.white_text
{
    color: white;
}

.header_text
{
    font-size: 12px;
}

.address_text
{
    font-size: 10px;
}

::v-deep .v-btn {
  padding-left: 5px;
  padding-right: 5px;
  padding-top: 5px;
  padding-bottom:5px;
}

.v-card__title {
  color: white;
}



</style>