import { createRouter, createWebHistory } from 'vue-router'
import Descriptives from '@/views/outputs/Descriptives.vue'
import Experimental from '@/views/outputs/Experimental.vue'
import Winrates from "@/views/outputs/Winrates.vue"
import Individual from "@/views/outputs/Individual.vue"
import Sliding from "@/views/outputs/Sliding.vue"
import Criteria from "@/views/outputs/Criteria.vue"
import Methods from "@/views/Methods.vue"
import Statistics from "@/views/Statistics.vue"
import Faq from "@/views/Faq.vue"
import Change from "@/views/ChangeLog.vue"

const routes = [
    {
        path: "/methods",
        name: "Methods",
        component: Methods
    },
    {
        path: "/faq",
        name: "Faq",
        component: Faq
    },
    {
        path: "/changelog",
        name: "Change",
        component: Change
    },
    {
        path: "/",
        redirect: '/statistics/criteria'
    },
    {
        path: "/statistics",
        name: "Statistics",
        component: Statistics,
        redirect: '/statistics/criteria',
        children: [
            {
                path: 'descriptives',
                component: Descriptives
            },
            {
                path: 'winrates',
                component: Winrates
            },
            {
                path: "experimental",
                component: Experimental
            },
            {
                path: 'criteria',
                component: Criteria
            },
            {
                path: 'individual',
                component: Individual
            },
            {
                path: 'sliding',
                component: Sliding
            }
        ]
    }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

export default router
