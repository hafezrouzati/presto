import { createApp, ref } from 'vue';
import { createVuetify, ThemeDefinition } from 'vuetify';
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { aliases, mdi } from 'vuetify/iconsets/mdi'

import Datepicker from '@vuepic/vue-datepicker';
import '@vuepic/vue-datepicker/dist/main.css'

import '@mdi/font/css/materialdesignicons.css' 
import App from './App.vue';
import { router } from './router';

import "./assets/global.css";

const app = createApp(App);

const myCustomLightTheme = {
    dark: false,
    colors: {
      background: '#FFFFFF',
      surface: '#FFFFFF',
      primary: '#6200EE',
      'primary-darken-1': '#3700B3',
      secondary: '#03DAC6',
      'secondary-darken-1': '#018786',
      error: '#B00020',
      info: '#2196F3',
      success: '#4CAF50',
      warning: '#FB8C00',
    }
  }

const vuetify = createVuetify({ components, directives,
    icons: {
        defaultSet: 'mdi',
        aliases,
        sets: {
            mdi,
        }
    }
});

var userPrincipal = ref(null);
app.provide('userPrincipal', userPrincipal);
app.use(router);
app.use(vuetify);
app.component('Datepicker', Datepicker);
app.mount("#app");
