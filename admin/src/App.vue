<script setup>
import AdminLayout from './layouts/AdminLayout.vue'
import NetworkStatus from './components/common/NetworkStatus.vue'
</script>

<template>
  <v-app>
    <NetworkStatus />
    <AdminLayout />
  </v-app>
</template>

<style>
/* Global styles with consistent typography and spacing */
* {
  box-sizing: border-box;
}

html {
  font-size: 16px; /* Base font size for rem calculations */
  line-height: 1.5;
}

body {
  margin: 0;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', Arial, sans-serif;
  font-weight: 400;
  font-size: 1rem;
  line-height: 1.6;
  color: #1a1a1a;
  background-color: #f5f5f5;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}

/* Typography hierarchy */
h1, h2, h3, h4, h5, h6 {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', Arial, sans-serif;
  font-weight: 600;
  line-height: 1.3;
  margin: 0 0 1rem 0;
  color: #1a1a1a;
  letter-spacing: -0.02em;
}

h1 { font-size: 2.5rem; font-weight: 700; }
h2 { font-size: 2rem; font-weight: 600; }
h3 { font-size: 1.5rem; font-weight: 600; }
h4 { font-size: 1.25rem; font-weight: 600; }
h5 { font-size: 1.125rem; font-weight: 600; }
h6 { font-size: 1rem; font-weight: 600; }

/* Text utilities */
.text-body-1 {
  font-size: 1rem;
  font-weight: 400;
  line-height: 1.6;
}

.text-body-2 {
  font-size: 0.875rem;
  font-weight: 400;
  line-height: 1.5;
}

.text-caption {
  font-size: 0.75rem;
  font-weight: 400;
  line-height: 1.4;
  color: #64748b;
}

.text-overline {
  font-size: 0.75rem;
  font-weight: 500;
  line-height: 1.4;
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

/* Font weight utilities */
.font-weight-light { font-weight: 300; }
.font-weight-regular { font-weight: 400; }
.font-weight-medium { font-weight: 500; }
.font-weight-bold { font-weight: 600; }
.font-weight-black { font-weight: 700; }

/* Spacing utilities following 8px base unit */
.pa-0 { padding: 0 !important; }
.pa-1 { padding: 0.5rem !important; }
.pa-2 { padding: 1rem !important; }
.pa-3 { padding: 1.5rem !important; }
.pa-4 { padding: 2rem !important; }
.pa-5 { padding: 2.5rem !important; }
.pa-6 { padding: 3rem !important; }

.ma-0 { margin: 0 !important; }
.ma-1 { margin: 0.5rem !important; }
.ma-2 { margin: 1rem !important; }
.ma-3 { margin: 1.5rem !important; }
.ma-4 { margin: 2rem !important; }
.ma-5 { margin: 2.5rem !important; }
.ma-6 { margin: 3rem !important; }

/* Directional spacing */
.pt-0 { padding-top: 0 !important; }
.pt-1 { padding-top: 0.5rem !important; }
.pt-2 { padding-top: 1rem !important; }
.pt-3 { padding-top: 1.5rem !important; }
.pt-4 { padding-top: 2rem !important; }

.pb-0 { padding-bottom: 0 !important; }
.pb-1 { padding-bottom: 0.5rem !important; }
.pb-2 { padding-bottom: 1rem !important; }
.pb-3 { padding-bottom: 1.5rem !important; }
.pb-4 { padding-bottom: 2rem !important; }

.pl-0 { padding-left: 0 !important; }
.pl-1 { padding-left: 0.5rem !important; }
.pl-2 { padding-left: 1rem !important; }
.pl-3 { padding-left: 1.5rem !important; }
.pl-4 { padding-left: 2rem !important; }

.pr-0 { padding-right: 0 !important; }
.pr-1 { padding-right: 0.5rem !important; }
.pr-2 { padding-right: 1rem !important; }
.pr-3 { padding-right: 1.5rem !important; }
.pr-4 { padding-right: 2rem !important; }

.mt-0 { margin-top: 0 !important; }
.mt-1 { margin-top: 0.5rem !important; }
.mt-2 { margin-top: 1rem !important; }
.mt-3 { margin-top: 1.5rem !important; }
.mt-4 { margin-top: 2rem !important; }

.mb-0 { margin-bottom: 0 !important; }
.mb-1 { margin-bottom: 0.5rem !important; }
.mb-2 { margin-bottom: 1rem !important; }
.mb-3 { margin-bottom: 1.5rem !important; }
.mb-4 { margin-bottom: 2rem !important; }

.ml-0 { margin-left: 0 !important; }
.ml-1 { margin-left: 0.5rem !important; }
.ml-2 { margin-left: 1rem !important; }
.ml-3 { margin-left: 1.5rem !important; }
.ml-4 { margin-left: 2rem !important; }

.mr-0 { margin-right: 0 !important; }
.mr-1 { margin-right: 0.5rem !important; }
.mr-2 { margin-right: 1rem !important; }
.mr-3 { margin-right: 1.5rem !important; }
.mr-4 { margin-right: 2rem !important; }

/* Shadow utilities for flat design */
.elevation-0 { box-shadow: none !important; }
.elevation-1 { box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1) !important; }
.elevation-2 { box-shadow: 0 4px 8px rgba(0, 0, 0, 0.12) !important; }
.elevation-3 { box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15) !important; }

/* Custom scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 4px;
  transition: background-color 0.2s ease;
}

::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}

::-webkit-scrollbar-corner {
  background: #f1f1f1;
}

/* Focus styles for accessibility */
*:focus-visible {
  outline: 2px solid #f9a825;
  outline-offset: 2px;
  border-radius: 4px;
}

/* Remove default focus styles */
*:focus {
  outline: none;
}

/* Disable animations/transitions across admin */
*, *::before, *::after { transition: none !important; animation: none !important; }

/* Ensure consistent border radius */
.rounded { border-radius: 0.5rem !important; }
.rounded-sm { border-radius: 0.25rem !important; }
.rounded-lg { border-radius: 0.75rem !important; }
.rounded-xl { border-radius: 1rem !important; }
</style>
