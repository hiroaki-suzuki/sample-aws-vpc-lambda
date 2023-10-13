<script lang="ts" setup>
import { API } from 'aws-amplify'
import { ref } from 'vue'

const message = ref('ボタンをクリックしてください')

function getHelloWorld() {
  API.get('api', '/hello', {})
    .then((req) => {
      console.log(req)
      message.value = req.message
    })
    .catch((err) => {
      console.log(err)
      message.value = 'エラーが発生しました'
    })
}
</script>

<template>
  <main>
    <h1>{{ message }}</h1>
    <button @click="getHelloWorld">取得</button>
  </main>
</template>

<style scoped>
main {
  text-align: center;
}

button {
  background-color: #4caf50;
  border: none;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  font-size: 16px;
  margin: 4px auto;
  padding: 12px 24px;
}
</style>