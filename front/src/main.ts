import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { Amplify } from 'aws-amplify'

console.log(import.meta.env)
Amplify.configure({
  API: {
    endpoints: [
      {
        name: 'api',
        endpoint: import.meta.env.VITE_API_URL
      }
    ]
  }
})

const app = createApp(App)
app.use(router)
app.mount('#app')
