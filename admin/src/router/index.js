import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../pages/Dashboard.vue'
import ShopList from '../pages/ShopList.vue'
import ShopForm from '../pages/ShopForm.vue'
import ProposalReview from '../pages/ProposalReview.vue'
import Login from '../pages/Login.vue'
import Register from '../pages/Register.vue'

const routes = [
    { path: '/login', name: 'Login', component: Login, meta: { standalone: true } },
    { path: '/register', name: 'Register', component: Register, meta: { standalone: true } },
    { path: '/', redirect: '/dashboard' },
    {
        path: '/dashboard',
        name: 'Dashboard',
        component: Dashboard,
        meta: { requiresAuth: true }
    },
    {
        path: '/shops',
        name: 'ShopList',
        component: ShopList,
        meta: { requiresAuth: true }
    },
    {
        path: '/shops/create',
        name: 'ShopCreate',
        component: ShopForm,
        meta: { requiresAuth: true }
    },
    {
        path: '/shops/:id/edit',
        name: 'ShopEdit',
        component: ShopForm,
        props: true,
        meta: { requiresAuth: true }
    },
    {
        path: '/proposals',
        name: 'ProposalReview',
        component: ProposalReview,
        meta: { requiresAuth: true }
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

// Global auth guard
router.beforeEach((to, from, next) => {
    const requiresAuth = to.matched.some(record => record.meta?.requiresAuth)
    const token = localStorage.getItem('admin_token')

    if (requiresAuth && !token) {
        next({ name: 'Login', query: { redirect: to.fullPath } })
    } else if ((to.name === 'Login' || to.name === 'Register') && token) {
        // Already logged in -> go to dashboard
        next({ name: 'Dashboard' })
    } else {
        next()
    }
})

export default router
