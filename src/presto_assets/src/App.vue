<template>
  <v-app>
      <v-app-bar app color="primary" height="20px;" dense dark>
        <!-- <template v-slot:image>
          <v-img
            gradient="to top right, rgba(207, 159, 255, 1), rgba(224, 176, 255, 1)">
          </v-img>
        </template> -->
        <v-app-bar-nav-icon @click.stop="drawer = !drawer"></v-app-bar-nav-icon>
      <v-app-bar-title>PRESTO Escrow, Title, & Trust</v-app-bar-title>
    </v-app-bar>
        <v-navigation-drawer app v-model="drawer">
          <v-list dense nav>
            <v-divider></v-divider>

            <v-list-item v-if="userAuthenticated" v-for="item in navItems" :key="item.title" link @click="router.push(item.route)">   
                <v-list-item-icon>
                  <v-icon>{{ item.icon }}</v-icon>
                </v-list-item-icon>

                <v-list-item-content>
                  <v-list-item-title>{{ item.title }}</v-list-item-title>
                </v-list-item-content>
                
              </v-list-item>
              <v-list-item @click="logout()" v-if="userAuthenticated">
                <v-list-item-icon>
                  <v-icon>mdi-account</v-icon>
                </v-list-item-icon>

                <v-list-item-content>
                  <v-list-item-title>Logout</v-list-item-title>
                </v-list-item-content>
              </v-list-item>
            
          </v-list>
        </v-navigation-drawer>              
              <div class="main_container">
              <v-main>
                  <div v-if="userAuthenticated"> 
                      <router-view></router-view>
                  </div>

                  <div v-else>          
                        <v-container fill-height>
                          <v-row align="center">
                            <v-col align="center">
                              
                                <v-btn color="primary" @click="login">Login with Internet Identity</v-btn>
                              
                            </v-col> 
                          </v-row>  
                        </v-container>
                  </div>
              </v-main>
              </div>
  </v-app>

</template>

<script setup>
  import { presto } from '../../declarations/presto';
  import { whoami } from '../../declarations/whoami';
  import { AuthClient } from "@dfinity/auth-client";
  import { Actor, HttpAgent } from "@dfinity/agent";
  import { Principal } from "@dfinity/principal";
  import { createActor } from '../../declarations/whoami';

  import { ref, onMounted, inject, provide } from 'vue';
  import { useRouter, useRoute } from 'vue-router';

  var userID = ref('awesome');
  var userPrincipal = inject('userPrincipal');

  const router = useRouter();
  const route = useRoute();


  var drawer = ref(false);
  var navItems = [
      { title: 'Home', icon: 'mdi-home', route: "/" },
      { title: 'New Escrow', icon: 'mdi-home', route: "/newescrow" },
      { title: 'My Escrows', icon: 'mdi-account-box', route: "/escrows" },
  ];

  var authClient;

  var userAuthenticated = ref(false);

  async function handleAuthenticated() {
    userAuthenticated.value = true;

    let userIdentity = await authClient.getIdentity();

    userID.value = userIdentity.getPrincipal().toString();
    userPrincipal.value = userIdentity.getPrincipal();

    console.log("USER ID");
    console.log(userID.value);
  };

  async function logout() {
    await authClient.logout();
    userAuthenticated.value = false;
  }

  async function login()
  {
      await authClient.login({
          onSuccess: async () => {
            handleAuthenticated(authClient);
          },
      });
  };

  async function bindLoginButton() {
    const loginButton = document.getElementById("loginButton");
    loginButton.onclick = async () => {
        await authClient.login({
          onSuccess: async () => {

            handleAuthenticated(authClient);
          },
          //identityProvider: 'http://127.0.0.1:8000/?canisterId=rno2w-sqaaa-aaaaa-aaacq-cai'
        });
      };
  }

  onMounted( async () => {

    authClient = await AuthClient.create();  

    if (await authClient.isAuthenticated()) {
      handleAuthenticated(authClient);
    }

  });

</script>

<style>
body {
  margin: 0;
}

.main_container {
  padding: 80px 0px 0px 0px;
}

.nav_container {

}
</style>

