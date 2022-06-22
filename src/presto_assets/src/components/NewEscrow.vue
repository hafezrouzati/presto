<template><br/><br/>
<v-card height="200px" width="100%" elevation="24">
    <v-card-title>New Escrow</v-card-title>
    <v-card-subtitle>Select Expiration Time</v-card-subtitle>
    <v-row align="center">
        <v-col align="center">        
            <Datepicker v-model="selectedDate"></Datepicker>
            <v-btn color="primary" @click="createEscrow">Create New Escrow</v-btn>
        </v-col>
    </v-row>                   
</v-card>
</template>

<script setup>
    import { inject, ref, onMounted } from 'vue'
    import { useRoute, useRouter } from 'vue-router';
    import { presto } from '../../../declarations/presto';
    
    const router = useRouter();
    const route = useRoute();   

    var userPrincipal = inject('userPrincipal');

    var selectedDate = ref (new Date(Date.now()));

    async function createEscrow()
    {
        const escrowID = await presto.createEscrow(userPrincipal.value, 10000);
        console.log("created new escrow");
        console.log(escrowID);
        router.push({ name: "escrow", params: { escrowID: escrowID }});

        console.log(selectedDate);
        
        var dateNanoseconds = parseInt(selectedDate.toString() + "000000");
        await presto.setEscrowUnlockTime(escrowID, dateNanoseconds);
    }

    onMounted( async () => {
       
    });

</script>

<style>

</style>
