<template>
  <div class="map-picker">
    <div ref="mapContainer" class="maplibre-map" />
    <div class="coords mt-2 text-caption">
      緯度: {{ latitude?.toFixed(6) || '-' }} / 経度: {{ longitude?.toFixed(6) || '-' }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'
import maplibregl, { Map, Marker } from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

interface Props {
  latitude?: number
  longitude?: number
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'update:latitude', value: number | undefined): void
  (e: 'update:longitude', value: number | undefined): void
}>()

const mapContainer = ref<HTMLDivElement | null>(null)
let map: Map | null = null
let marker: Marker | null = null

const defaultCenter: [number, number] = [139.767052, 35.681167] // Tokyo Station (lng, lat)

const initMap = () => {
  if (!mapContainer.value) return
  const center: [number, number] = [
    props.longitude ?? defaultCenter[0],
    props.latitude ?? defaultCenter[1]
  ]
  map = new maplibregl.Map({
    container: mapContainer.value,
    style: 'https://demotiles.maplibre.org/style.json',
    center,
    zoom: props.latitude && props.longitude ? 14 : 11,
    attributionControl: true
  })

  map.addControl(new maplibregl.NavigationControl({ showZoom: true }), 'top-right')

  // Create marker if coords set
  if (props.latitude !== undefined && props.longitude !== undefined) {
    marker = new maplibregl.Marker({ draggable: true })
      .setLngLat([props.longitude, props.latitude])
      .addTo(map)
    marker.on('dragend', () => {
      const pos = marker!.getLngLat()
      emit('update:latitude', pos.lat)
      emit('update:longitude', pos.lng)
    })
  }

  // Set marker on click
  map.on('click', (e) => {
    const { lng, lat } = e.lngLat
    if (!marker) {
      marker = new maplibregl.Marker({ draggable: true })
        .setLngLat([lng, lat])
        .addTo(map!)
      marker.on('dragend', () => {
        const pos = marker!.getLngLat()
        emit('update:latitude', pos.lat)
        emit('update:longitude', pos.lng)
      })
    } else {
      marker.setLngLat([lng, lat])
    }
    emit('update:latitude', lat)
    emit('update:longitude', lng)
  })
}

onMounted(initMap)

onBeforeUnmount(() => {
  if (map) {
    map.remove()
    map = null
  }
})

// Keep marker in sync when props change externally
watch(() => [props.latitude, props.longitude] as const, ([lat, lng]) => {
  if (!map) return
  if (lat === undefined || lng === undefined) return
  if (!marker) {
    marker = new maplibregl.Marker({ draggable: true })
      .setLngLat([lng, lat])
      .addTo(map)
    marker.on('dragend', () => {
      const pos = marker!.getLngLat()
      emit('update:latitude', pos.lat)
      emit('update:longitude', pos.lng)
    })
  } else {
    marker.setLngLat([lng, lat])
  }
  map.setCenter([lng, lat])
})
</script>

<style scoped>
.maplibre-map {
  width: 100%;
  height: 320px;
  border-radius: 8px;
  border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  overflow: hidden;
}
</style>

