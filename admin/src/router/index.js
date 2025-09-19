import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../pages/Dashboard.vue'
import ShopList from '../pages/ShopList.vue'
import ShopForm from '../pages/ShopForm.vue'
import ProposalReview from '../pages/ProposalReview.vue'

const routes = [
    {
        path: '/',
        redirect: '/dashboard'
    },
    {
        path: '/dashboard',
        name: 'Dashboard',
        component: Dashboard
    },
    {
        path: '/shops',
        name: 'ShopList',
        component: ShopList
    },
    {
        path: '/shops/create',
        name: 'ShopCreate',
        component: ShopForm
    },
    {
        path: '/shops/:id/edit',
        name: 'ShopEdit',
        component: ShopForm,
        props: true
    },
    {
        path: '/proposals',
        name: 'ProposalReview',
        component: ProposalReview
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router