<template>
  <div
    v-if="$nav.currentPage > 1"
    class="absolute bottom-3 right-6 text-[37px] font-extralight text-[#fdfdfd]"
  >
    {{ $nav.currentPage }}
  </div>
</template>
