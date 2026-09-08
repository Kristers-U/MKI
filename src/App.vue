<template>
  <div id="app">
  
  <div class="container">
    <aside class="sidebar">
      <div class="btns">
        <button @click="active = 'column'; prepareGraphWindow = false;">3D</button>
        <button @click="active = 'graph'; prepareGraphWindow= true;">Grafiks</button>
      </div>
      
      <div class="forms">
        <fieldset>
          <legend>Ievade</legend>

          <label>Kolonnas augstums, H = 
            <input v-model.number="H" type="number" min="0" step="any">(m)
          </label>

          <label>Šķērsgriezuma platums, B = 
            <input v-model.number="B" type="number" min="0" step="any">(mm)
          </label>

          <label>Šķērsgriezuma augstums, D = 
            <input v-model.number="D" type="number" min="0" step="any">(mm)
          </label>

          <label id="t">Sienas biezums, t = 
            <input v-model.number="t" type="number" min="0" step="any" @change="valid">(mm)
            <span class="error" v-if="tMessage">{{ tMessage }}</span>
          </label>
          

          <label>Materiāla stiprība, fy = 
            <input v-model.number="f" type="number" min="0" step="any">(MPa)
          </label>

          <label>Elastības modulis, E = 
            <input v-model.number="E" type="number" min="0" step="any">(MPa)
          </label>

          <label>Fiksācijas koeficients, K = 
            <input v-model.number="K" type="number" min="0" step="any">
          </label>
        </fieldset>

        <fieldset>

          <label id="SF">Drošības koeficients, SF ≈ 
            <output @change="valid">{{ SF.toFixed(2) }} &nbsp;</output>
            <span class="error" v-if="sfMessage">{{ sfMessage }}</span>
          </label>
          
        </fieldset>
      </div>
    </aside>

    <main class="viewer">
      <ThreeColumn  :visible="active === 'column'" v-show="active === 'column'" :H="H" :B="B/100" :D="D/100" :t="t/100" />
      
      <ResultsGraph v-show="active === 'graph'" :H="H" :E="E" :K="K" :B="B" :D="D" :t="t" :prepareGraphWindow="prepareGraphWindow"/>
      <div class="resultTable" v-show="active === 'graph'">
      
        <table>

          <thead>
            <tr>
              <th>Lielums</th>
              <th>Apzīmējums</th>
              <th>Vērtība</th>
              <th>Vienības</th>
            </tr>
          </thead>

          <tbody>

            <tr>
              <th>Šķērsgriezuma laukums</th>
              <th>A</th>
              <th>{{ A.toFixed(2) }}</th>
              <th>mm<sup>2</sup></th>
            </tr>

            <tr>
              <th>Inerces moments</th>
              <th>I<sub>y</sub></th>
              <th>{{ (Iy / 1e6).toFixed(3) }} ×10<sup>6</sup></th>
              <th>mm<sup>4</sup></th>
            </tr>

            <tr>
              <th>Kritiskā spēka aprēķins (Eulera formula)</th>
              <th>N<sub>cr</sub></th>
              <th>{{ Ncr_kN.toFixed(3) }}</th>
              <th>kN</th>
            </tr>

          </tbody>

        </table>
      </div>
    </main>

    <div></div>
    
  </div>
  </div>

</template>


<script>
import ResultsGraph from "./components/ResultsGraph.vue";
import ThreeColumn from "./components/ThreeColumn.vue";

export default {
  data() {
    return {
      prepareGraphWindow: false,
      active: 'column',
      H: 5,
      B: 200,
      D: 300,
      t: 10,
      f: 355,
      E: 210000,
      K: 2,
      tMessage: "",
      sfMessage: ""
    };
  },
  mounted() {
    if (window.api?.ping) {
      window.api.ping().then(res => console.log(res)) // logs 'pong'
    }
  },

  methods: {
    valid() {
      if (this.t >= this.B / 2) {
        this.tMessage = "Kļūda! Sienas biezums pārsniedz pieļaujamo";
      } else {
        this.tMessage = "";
      }
      if (this.SF < 1) {
        this.sfMessage = "Konstrukcija nestabila!";
      } else {
        this.sfMessage = "";
      }
    }
  },
  computed: {
    A() {
      if (this.B <= 0 || this.D <= 0 || this.t <= 0) return 0;
      return 2*this.B * this.t + (this.D - 2*this.t) * this.t;
    },
    Iy() {
      if (this.B <= 0 || this.D <= 0 || this.t <= 0) return 0;
      return (this.B * Math.pow(this.D,3))/12 - ((this.B - this.t) * Math.pow(this.D - 2*this.t,3))/12;
    },
    Ncr() {
      if (this.H <= 0 || this.E <= 0 || this.K <= 0) return 0;
      const L = this.H * 1000;
      return (Math.PI**2 * this.E * this.Iy) / (Math.pow(this.K * L, 2));
    },
    Ncr_kN() {
      return this.Ncr * 1e-3;
    },
    SF() {
      if (this.A <= 0 || this.f <= 0) return 0;
      return this.Ncr / (this.A * this.f);
    }
  },
  components: {
    ResultsGraph,
    ThreeColumn
  }
};

</script>


<style scoped>
.error {
  color: red;
  font-size: 0.9rem;
  min-height: 1em;
}
html, body {
  height: 100%;
  margin: 0;
}
#app {
  height: 100vh;
  display: flex;
  flex-direction: column;
}
.forms{
  color: white;
}

.container {
  display: flex;
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: auto;
  min-height: 100vh;
}

.sidebar {
  width: 340px;
  background-color: rgb(22, 21, 21);
}

.viewer {
  flex: 1;
  min-width: 0;     /* allow flex shrink */
  position: relative;
  display: flex;
  height: 100%;
  flex-direction: column;
}

.viewer canvas {
  flex: 1;
}
legend{
  font-size: large;
  padding: 0 15px;
  font-weight: 600;
}
fieldset {
  font-size: 16px;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1rem;
  border: 1px solid #ccc;
}
label {display: block;}
input {
  width: 70%;
  padding: 5px;
  margin: 3px 0;
  display: inline-block;
  border: 1px solid #ccc;
  border-radius: 4px;
  box-sizing: border-box;
  margin-right: 5px;
}

.btns{
  width:100%;
  display: flex;
  justify-content: center;
  justify-items: auto;
}

button {
  border: 2px solid white;
  color: white;
  background-color: rgb(10, 10, 10);
  margin: 10px 5px;
  padding: 5% 15%;
  border-radius: 10px;
}
.resultTable{
  height: 100%;
}
* {
  box-sizing: border-box;
  font-family: system-ui, sans-serif;
}

table {
    font-size: 15px;
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    border-spacing: 0;
    width: 100%;
    height: 100%;
}
table td, table th {
    text-align: left;
    padding: 8px;
}
thead th {
    padding-top: 11px;
    padding-bottom: 11px;
    background-color: rgb(10, 10, 10);
    color: white;
}
tbody th {
    padding-top: 11px;
    padding-bottom: 11px;
    background-color: rgb(15, 15, 15);
    color: white;
}
table.table1, table.table1 th, table.table1 td {
  border: 1px solid;
}

table.color, table.color th, table.color td {
  border: 1px solid rgb(0, 0, 0);
}

table.bordercollapse, table.bordercollapse th, table.bordercollapse td {
  border: 1px solid;
}
table.bordercollapse {
  border-collapse: collapse;
}

table.padding,table.padding td,table.padding th {
  border: 1px solid;
}
table.padding {
  border-collapse: collapse;
}
table.padding td,table.padding th {
  padding: 10px;
  text-align: left;
}

table.borderspacing, table.borderspacing th, table.borderspacing td {
  border: 1px solid;
}
table.borderspacing {
  border-collapse: separate;
  border-spacing: 15px;
}
table.onlytableborder {
  border: 1px solid;
}

</style>
