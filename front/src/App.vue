<script lang="ts" setup>
import { RouterView } from 'vue-router'
</script>

<template>
  <header>
    <div class="wrapper">
      <h1 class="title">VPC Lambda サンプル</h1>
    </div>
  </header>

  <RouterView />
</template>

<style scoped>
header {
  margin-bottom: 40px;
}

.title {
  font-size: 24px;
  text-align: center;
  color: #737373;
}
</style>