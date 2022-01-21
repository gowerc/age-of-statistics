<template>
<nav class="navbar navbar-expand-sm navbar-dark bg-dark px-md-4 mb-3">
    <div class="container-fluid">
        
        <a class="navbar-brand" href="/">
            Age of Statistics
        </a>
        
        <button class="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navbarNavDropdown"
            aria-controls="navbarNavDropdown"
            aria-expanded="false"
            aria-label="Toggle navigation">
            <span class="navbar-toggler-icon" />
        </button>
        
        <div
            id="navbarNavDropdown"
            class="collapse navbar-collapse justify-content-end">
            
            <ul class="navbar-nav">
                
                <li class="nav-item">
                    <router-link
                        class="nav-link"
                        to="/statistics">
                        
                        Statistics
                    </router-link>
                </li>
                
                
                <li class="nav-item">
                    <router-link
                        class="nav-link"
                        to="/methods">
                        
                        Methods
                    </router-link>
                </li>
                
                
                <li class="nav-item">
                    <router-link
                        class="nav-link"
                        to="/faq">
                        
                        FAQ
                    </router-link>
                </li>
                
                
            </ul>
        </div>
    </div>
</nav>
</template>


<style scoped>
.navbar-brand {
    font-family: 'Secular One', sans-serif;
    font-size: 22px;
    color: #DDD !important;
}
</style>