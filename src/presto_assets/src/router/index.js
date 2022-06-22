import { createRouter, createWebHashHistory } from 'vue-router';

import About from '../components/About.vue'
import Home from '../components/Home.vue';
import Escrow from '../components/Escrow.vue';
import EscrowList from '../components/EscrowList.vue';
import NewEscrow from '../components/NewEscrow.vue';
import ViewDocument from '../components/ViewDocument.vue';

export const routes = [
    { path: '/', component: Home },
    { path: '/about', component: About },
    { path: '/escrows', component: EscrowList },
    { path: '/newescrow', component: NewEscrow },
    { path: '/escrow/:escrowID', name: 'escrow', component: Escrow},
    { path: '/viewdocument/:assetID', name: 'viewdocument', component: ViewDocument}
]

export const router = createRouter( {
    history: createWebHashHistory(),
    routes
});

