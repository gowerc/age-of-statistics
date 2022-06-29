<template>
<nav class="navbar navbar-expand-sm navbar-dark bg-dark py-0 w-100 pt-1">
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
                
                
                
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="navbarDropdownMenuLink" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        Statistics
                    </a>
                    <ul class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
                        <li>
                            <router-link
                                class="dropdown-item"
                                to="/statistics">
                                Civilisation
                            </router-link>
                        </li>
                        <li>
                            <router-link
                                class="dropdown-item"
                                to="/global">
                                Game
                            </router-link>
                        </li>
                    </ul>
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
                
                <li class="nav-item">
                    <router-link
                        class="nav-link"
                        to="/changelog">
                        
                        Change-Log
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

.navbar {
    box-shadow: 0px 0px 3px 3px #212529;
}
</style>