import { createRouter, createWebHistory } from 'vue-router'
import Descriptives from '@/views/Descriptives.vue'
import Winrates from "@/views/Winrates.vue"
import Methods from "@/views/Methods.vue"
import Statistics from "@/views/Statistics.vue"

const routes = [
    {
        path: "/methods",
        name: "Methods",
        component: Methods
    },
    {
        path: "/statistics",
        name: "Statistics",
        component: Statistics,
        redirect: '/statistics/descriptives',
        children: [
            {
                path: 'descriptives',
                component: Descriptives
            },
            {
                path: 'winrates',
                component: Winrates
            }
        ]
    }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

export default router
