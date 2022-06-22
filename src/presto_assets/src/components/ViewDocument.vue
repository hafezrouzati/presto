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
    <v-card height="100%" width="100%" raised>
        <iframe id="pdf_frame" width="100%" height="1000"></iframe>
    </v-card>
</template>

<script setup>
    import { inject, ref, onMounted } from 'vue';
    import { useRoute, useRouter } from 'vue-router';
    import { presto } from '../../../declarations/presto';

    const router        = useRouter();
    const route         = useRoute();

    const assetID     = ref(route.params.assetID);

    var loading = ref (false);
    
    onMounted( async () => {
        loadDocument();
    });

    async function loadDocument() 
    {
        loading.value = true;

        let documentArray = await presto.getAsset(assetID.value);
        let doc = documentArray[0]

        var blobContent = new Blob([doc.buffer], {type: "application/pdf"});

        var documentURL = URL.createObjectURL(blobContent);

        var pdfFrame = document.getElementById("pdf_frame");
        pdfFrame.src = documentURL;
        
        loading.value = false;
    };


</script>

<style>

</style>