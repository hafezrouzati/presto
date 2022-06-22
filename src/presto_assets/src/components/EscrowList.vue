<template>
    <v-list dense>
        <v-list-item v-for="item in escrowList" :key="item.title" link @click="router.push({ name: 'escrow', params: { escrowID: item.escrowID } })">   
            <v-list-item-content>
                <v-list-item-title>{{ item.title }}</v-list-item-title>
            </v-list-item-content>
        </v-list-item>
    </v-list>
</template>

<script setup>
    import { inject, onMounted, ref } from 'vue';
    import { presto } from '../../../declarations/presto';
    import { useRouter, useRoute } from 'vue-router';

    var userID = inject('userID');
    var userPrincipal = inject('userPrincipal');
    var escrowList = ref([]);
    var escrows = null;

    const router = useRouter();
    const route = useRoute();

    onMounted( async () => {
        escrows = await presto.getEscrowsForUser(userPrincipal.value);
        console.log(escrows);

        var i = 0;
        for (;i<escrows.length;i++)
        {
            let escrowID = escrows[i];

            escrowList.value.push({
                title: escrowID,
                escrowID: escrowID
            });
        }
    });

</script>

<style>

.v-list-item--active {
  background-color: lightgrey;
  color: white;
}

</style>
