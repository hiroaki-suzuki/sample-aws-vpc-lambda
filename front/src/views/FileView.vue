<script lang="ts" setup>
import { onMounted, ref } from 'vue'
import { API } from 'aws-amplify'

type UploadFile = {
  id: string
  filename: string
}

const uploadFiles = ref<UploadFile[]>([])
const file = ref<File>(new File([], ''))
const errorMessage = ref('')
const isLoading = ref(false)

function setFile(event: Event) {
  const target = event.target as HTMLInputElement
  const files = target.files
  if (files && files[0]) {
    file.value = files[0]
  }
}

async function getFiles() {
  isLoading.value = true
  errorMessage.value = ''
  const response = await API.get('api', '/files', {})
    .catch((err) => {
      console.log(err)
      errorMessage.value = 'ファイル一覧の取得に失敗しました。'
    })
    .finally(() => {
      isLoading.value = false
    })

  uploadFiles.value = response['files']
}

async function uploadFile() {
  if (file.value.size === 0) {
    errorMessage.value = 'ファイルを選択してください。'
    return
  }

  isLoading.value = true
  errorMessage.value = ''
  const formData = new FormData()
  formData.append('file', file.value)
  await API.post('api', '/file', { body: formData })
    .catch((err) => {
      console.log(err)
      errorMessage.value = 'ファイルのアップロードに失敗しました。'
    })
    .finally(() => {
      isLoading.value = false
    })

  await getFiles()
}

async function downloadFile(filename: string) {
  isLoading.value = true
  errorMessage.value = ''
  const encodedFilename = encodeURIComponent(filename)
  const response = await API.get('api', `/file/${encodedFilename}`, { response: true })
    .catch((err) => {
      console.log(err)
      errorMessage.value = 'ファイルのダウンロードに失敗しました。'
    })
    .finally(() => {
      isLoading.value = false
      errorMessage.value = ''
    })

  // base64エンコードされたデータをBlobとして変換
  const byteCharacters = atob(response.data)
  const byteNumbers = new Array(byteCharacters.length)
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i)
  }
  const byteArray = new Uint8Array(byteNumbers)
  const mimeType = response.headers['mimeType']
  const blob = new Blob([byteArray], { type: mimeType })
  const url = window.URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  a.parentNode?.removeChild(a)
}

onMounted(() => {
  getFiles()
})
</script>

<template>
  <main>
    <p class="error-message">{{ errorMessage }}</p>
    <input class="file-input" type="file" @change="setFile" />
    <button class="upload-file-btn" @click="uploadFile">アップロード</button>
    <div class="loader-container">
      <div :class="{ active: isLoading }" class="loader"></div>
    </div>

    <ul class="files">
      <li v-for="file in uploadFiles" :key="file.id">
        <a @click="downloadFile(file.filename)">{{ file.filename }}</a>
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

.file-input {
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 16px;
  margin: 4px auto;
  padding: 6px 24px;
  width: 70%;
}

.upload-file-btn {
  background-color: #4caf50;
  border: none;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  font-size: 16px;
  margin-left: 10px;
  padding: 10px 24px;
}

.files {
  margin-top: 20px;
  list-style: none;
  padding: 0;
}

.files li {
  padding: 3px 5px;
  min-height: 30px;
}

.files li:nth-child(odd) {
  background-color: #f2f2f2;
}

.files li a {
  cursor: pointer;
}
</style>