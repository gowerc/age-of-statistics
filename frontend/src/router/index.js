import { createRouter, createWebHistory } from 'vue-router'

import Faq from "@/views/Faq.vue"
import Change from "@/views/ChangeLog.vue"
import Methods from "@/views/Methods.vue"

import Statistics from "@/views/Statistics/Statistics.vue"
import Descriptives from '@/views/Statistics/Descriptives.vue'
import Experimental from '@/views/Statistics/Experimental.vue'
import Winrates from "@/views/Statistics/Winrates.vue"
import Individual from "@/views/Statistics/Individual.vue"
import Sliding from "@/views/Statistics/Sliding.vue"
import Criteria from "@/views/Statistics/Criteria.vue"

import Global from "@/views/Global/Global.vue"
import EloDist from "@/views/Global/EloDist.vue"
import TimeTrends from "@/views/Global/TimeTrends.vue"

import Compare from "@/views/Compare.vue"

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
        path: "/compare",
        name: "Compare",
        component: Compare
    },
    {
        path: "/global",
        name: "Global",
        component: Global,
        redirect: '/global/timetrends',
        children: [
            {
                path: "timetrends",
                component: TimeTrends
            },
            {
                path: "elodist",
                component: EloDist
            }
        ]
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
