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
                    primary: '#007bff',
                    secondary: '#6c757d',
                    accent: '#17a2b8',
                    error: '#dc3545',
                    warning: '#ffc107',
                    info: '#17a2b8',
                    success: '#28a745',
                },
            },
        },
    },
})