import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import '@mdi/font/css/materialdesignicons.css'

export default createVuetify({
    icons: {
        defaultSet: 'mdi',
    },
    theme: {
        defaultTheme: 'light',
        themes: {
            light: {
                colors: {
                    primary: '#f9a825',      // Orange accent for buttons, links, active states
                    secondary: '#6c757d',    // Grey for secondary elements
                    accent: '#f9a825',       // Same as primary for consistency
                    error: '#dc3545',       // Red for errors
                    warning: '#ffc107',     // Yellow for warnings
                    info: '#17a2b8',        // Blue for info
                    success: '#28a745',     // Green for success
                    surface: '#ffffff',     // White for card backgrounds, sidebar
                    background: '#f5f5f5',  // Light grey for main content area
                    'on-surface': '#1a1a1a', // Dark text on white backgrounds
                    'on-primary': '#ffffff', // White text on orange backgrounds
                },
            },
        },
    },
    // Typography configuration for consistent font usage
    typography: {
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        fontWeightLight: 300,
        fontWeightRegular: 400,
        fontWeightMedium: 500,
        fontWeightBold: 600,
        fontWeightBlack: 700,
    },
    defaults: {
        // Global component defaults with consistent spacing and typography
        global: {
            ripple: false, // Disable ripple for flat design
        },
        VBtn: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 500; letter-spacing: 0.02em;',
            elevation: 0, // Flat design - no elevation by default
            rounded: 'lg', // Consistent border radius
        },
        VCard: {
            elevation: 1, // Subtle shadow for cards
            rounded: 'lg', // Consistent border radius
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
        },
        VAppBar: {
            elevation: 0, // Flat design for app bar
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
        },
        VNavigationDrawer: {
            elevation: 2, // Subtle shadow for navigation
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
        },
        VContainer: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
        },
        VListItem: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 500;',
            rounded: 'lg',
        },
        VTextField: {
            variant: 'outlined',
            density: 'comfortable',
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
            rounded: 'lg',
        },
        VSelect: {
            variant: 'outlined',
            density: 'comfortable',
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
            rounded: 'lg',
        },
        VChip: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 500;',
            rounded: 'lg',
        },
        VToolbarTitle: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 600; letter-spacing: -0.02em;',
        },
        VListItemTitle: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 500;',
        },
        VListItemSubtitle: {
            style: 'font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 400;',
        },
    },
})