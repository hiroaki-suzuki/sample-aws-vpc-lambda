<script lang="ts" setup>
import { API } from 'aws-amplify'
import { onMounted, ref } from 'vue'

type Message = {
  id: string
  message: string
}

const messages = ref<Message[]>([])
const message = ref('')
const errorMessage = ref('')
const isLoading = ref(false)

async function getMessages() {
  isLoading.value = true
  const response = await API.get('api', '/message', {})
    .catch((err) => {
      console.log(err)
      errorMessage.value = 'メッセージの取得に失敗しました。'
    })
    .finally(() => {
      isLoading.value = false
    })

  messages.value = response['messages']
}

async function saveMessage() {
  isLoading.value = true

  await API.post('api', '/message', { body: { message: message.value } })
    .catch((err) => {
      console.log(err)
      errorMessage.value = 'メッセージの登録に失敗しました。'
    })
    .finally(() => {
      isLoading.value = false
    })

  await getMessages()
}

onMounted(() => {
  getMessages()
})
</script>

<template>
  <main>
    <input v-model="message" class="message-input" maxlength="50" />
    <button class="save-message-btn" @click="saveMessage">保存</button>
    <div class="loader-container">
      <div :class="{ active: isLoading }" class="loader"></div>
    </div>

    <ul class="messages">
      <li v-for="message in messages" :key="message.id">
        {{ message.message }}
      </li>
    </ul>
  </main>
</template>

<style scoped>
main {
  margin: 0 auto;
  height: 200px;
  width: 600px;
}

.message-input {
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 16px;
  margin: 4px auto;
  padding: 12px 24px;
  width: 80%;
}

.save-message-btn {
  background-color: #4caf50;
  border: none;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  font-size: 16px;
  margin-left: 10px;
  padding: 10px 24px;
}

.loader-container {
  height: 50px;
}

.loader {
  display: none;
  margin: 0 auto;
  width: 50px;
  padding: 8px;
  aspect-ratio: 1;
  border-radius: 50%;
  background: #25b09b;
  --_m: conic-gradient(#0000 10%, #000), linear-gradient(#000 0 0) content-box;
  -webkit-mask: var(--_m);
  mask: var(--_m);
  -webkit-mask-composite: source-out;
  mask-composite: subtract;
  animation: l3 1s infinite linear;
}

.loader.active {
  display: block;
}

@keyframes l3 {
  to {
    transform: rotate(1turn);
  }
}

.messages {
  margin-top: 20px;
  list-style: none;
  padding: 0;
}

.messages li {
  padding: 3px 5px;
  min-height: 30px;
}

.messages li:nth-child(odd) {
  background-color: #f2f2f2;
}
</style>