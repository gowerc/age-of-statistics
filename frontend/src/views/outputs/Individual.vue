    <div id="civ-pick">
        <div class="form-group">
            <label for="civselect" class = "pe-3">Select a Civilisation:</label>
            <select name="cars" id="cars" v-model="civ" class = "form-control d-inline-block" style="width: auto;">
                <option v-bind:key="i_civ" v-for="i_civ in all_civs">
                    {% raw %}{{ i_civ }}{% endraw %}
                </option>
            </select>
        </div>

        <h3>Civilisation v Civilisation Win Rates</h3>
        <img 
            class="img-cohort img-standard"
            :src="'outputs/cohort_{{meta.id}}/cvc_wrNaive_' + civ + '_{{build_id}}.png'"
        >
    </div>
</template>



<script>
export default {
    props: ["path"],
}
</script>


<style scoped>
</style>