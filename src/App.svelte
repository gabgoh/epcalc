<script>
  
  import { scaleLinear } from "d3-scale";
  // import { Date } from "d3-time"
  import Chart from './Chart.svelte';
  import { onMount } from 'svelte';
  import { selectAll } from 'd3-selection'
  import { drag } from 'd3-drag';
  import queryString from "query-string";
  import Checkbox from './Checkbox.svelte';
  import Arrow from './Arrow.svelte';
  import { format } from 'd3-format'
  import { event } from 'd3-selection'

  import katex from 'katex';

  const legendheight = 67 

  function range(n){
    return Array(n).fill().map((_, i) => i);
  }

  function formatNumber(num) {
    return num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
  }

  function formatnumber(num) {
    if (num < 0.001) {
      return format(",.2r")(0)
    }
    return format(",.2r")(num)
  }  

  var sum = function(arr, bools){
    var x = 0
    for (var i = 0; i < arr.length; i++) {
      x = x + arr[i]*(bools[i] ? 1 : 0)
    }
    return x
  }

  var Integrators = {
    Euler    : [[1]],
    Midpoint : [[.5,.5],[0, 1]],
    Heun     : [[1, 1],[.5,.5]],
    Ralston  : [[2/3,2/3],[.25,.75]],
    K3       : [[.5,.5],[1,-1,2],[1/6,2/3,1/6]],
    SSP33    : [[1,1],[.5,.25,.25],[1/6,1/6,2/3]],
    SSP43    : [[.5,.5],[1,.5,.5],[.5,1/6,1/6,1/6],[1/6,1/6,1/6,1/2]],
    RK4      : [[.5,.5],[.5,0,.5],[1,0,0,1],[1/6,1/3,1/3,1/6]],
    RK38     : [[1/3,1/3],[2/3,-1/3,1],[1,1,-1,1],[1/8,3/8,3/8,1/8]]
  };

  // f is a func of time t and state y
  // y is the initial state, t is the time, h is the timestep
  // updated y is returned.
  var integrate=(m,f,y,t,h)=>{
    for (var k=[],ki=0; ki<m.length; ki++) {
      var _y=y.slice(), dt=ki?((m[ki-1][0])*h):0;
      for (var l=0; l<_y.length; l++) for (var j=1; j<=ki; j++) _y[l]=_y[l]+h*(m[ki-1][j])*(k[ki-1][l]);
      k[ki]=f(t+dt,_y,dt); 
    }
    for (var r=y.slice(),l=0; l<_y.length; l++) for (var j=0; j<k.length; j++) r[l]=r[l]+h*(k[j][l])*(m[ki-1][j]);
    return r;
  }

  function presetParameters(event) {
    const i = event.currentTarget.value
    const params = 
    [{R0: 2.2, D_incbation: 5.2, D_infectious: 2.9, CFR: 0.02, Time_to_death: 32},
     {R0: 1.5, D_incbation: 1.2, D_infectious: 1.9, CFR: 0.01, Time_to_death: 64},
     {R0: 1.2, D_incbation: 2.2, D_infectious: 4.9, CFR: 0.01, Time_to_death: 30},
     {R0: 1.1, D_incbation: 3.2, D_infectious: 1.4, CFR: 0.04, Time_to_death: 50},
     {R0: 1.1, D_incbation: 1.2, D_infectious: 1.2, CFR: 0.1,  Time_to_death: 132}]

    R0 = params[i].R0
    D_incbation = params[i].D_incbation
    D_infectious = params[i].D_infectious
    CFR = params[i].CFR
    Time_to_death = params[i].Time_to_death
  }

  $: Time_to_death     = 32
  $: logN              = Math.log(7e6)
  $: N                 = Math.exp(logN)
  $: I0                = 1
  $: R0                = 2.2
  $: D_incbation       = 5.2       
  $: D_infectious      = 2.9 
  $: D_recovery_mild   = (14 - 2.9)  
  $: D_recovery_severe = (31.5 - 2.9)
  $: D_hospital_lag    = 5
  $: D_death           = Time_to_death - D_infectious 
  $: CFR               = 0.02  
  $: InterventionTime  = 100  
  $: OMInterventionAmt = 2/3
  $: InterventionAmt   = 1 - OMInterventionAmt
  $: Time              = 220
  $: Xmax              = 110000
  $: dt                = 2
  $: P_SEVERE          = 0.2
  $: duration          = 7*12*1e10

  $: state = location.protocol + '//' + location.host + location.pathname + "?" + queryString.stringify({"Time_to_death":Time_to_death,
               "logN":logN,
               "I0":I0,
               "R0":R0,
               "D_incbation":D_incbation,
               "D_infectious":D_infectious,
               "D_recovery_mild":D_recovery_mild,
               "D_recovery_severe":D_recovery_severe,
               "CFR":CFR,
               "InterventionTime":InterventionTime,
               "InterventionAmt":InterventionAmt,
               "D_hospital_lag":D_hospital_lag,
               "P_SEVERE": P_SEVERE})

// dt, N, I0, R0, D_incbation, D_infectious, D_recovery_mild, D_hospital_lag, D_recovery_severe, D_death, P_SEVERE, CFR, InterventionTime, InterventionAmt, duration

  function get_solution(dt, N, I0, R0, D_incbation, D_infectious, D_recovery_mild, D_hospital_lag, D_recovery_severe, D_death, P_SEVERE, CFR, InterventionTime, InterventionAmt, duration) {

    var interpolation_steps = 40
    var steps = 110*interpolation_steps
    var dt = dt/interpolation_steps
    var sample_step = interpolation_steps

    var method = Integrators["RK4"]
    function f(t, x){

      // SEIR ODE
      if (t > InterventionTime && t < InterventionTime + duration){
        var beta = (InterventionAmt)*R0/(D_infectious)
      } else if (t > InterventionTime + duration) {
        var beta = 0.5*R0/(D_infectious)        
      } else {
        var beta = R0/(D_infectious)
      }
      var a     = 1/D_incbation
      var gamma = 1/D_infectious
      
      var S        = x[0] // Susectable
      var E        = x[1] // Exposed
      var I        = x[2] // Infectious 
      var Mild     = x[3] // Recovering (Mild)     
      var Severe   = x[4] // Recovering (Severe at home)
      var Severe_H = x[5] // Recovering (Severe in hospital)
      var Fatal    = x[6] // Recovering (Fatal)
      var R_Mild   = x[7] // Recovered
      var R_Severe = x[8] // Recovered
      var R_Fatal  = x[9] // Dead

      var p_severe = P_SEVERE
      var p_fatal  = CFR
      var p_mild   = 1 - P_SEVERE - CFR

      var dS        = -beta*I*S
      var dE        =  beta*I*S - a*E
      var dI        =  a*E - gamma*I
      var dMild     =  p_mild*gamma*I   - (1/D_recovery_mild)*Mild
      var dSevere   =  p_severe*gamma*I - (1/D_hospital_lag)*Severe
      var dSevere_H =  (1/D_hospital_lag)*Severe - (1/D_recovery_severe)*Severe_H
      var dFatal    =  p_fatal*gamma*I  - (1/D_death)*Fatal
      var dR_Mild   =  (1/D_recovery_mild)*Mild
      var dR_Severe =  (1/D_recovery_severe)*Severe_H
      var dR_Fatal  =  (1/D_death)*Fatal

      //      0   1   2   3      4        5          6       7        8          9
      return [dS, dE, dI, dMild, dSevere, dSevere_H, dFatal, dR_Mild, dR_Severe, dR_Fatal]
    }

    var v = [1 - I0/N, 0, I0/N, 0, 0, 0, 0, 0, 0, 0]
    var t = 0

    var P  = []
    var TI = []
    var Iters = []
    while (steps--) { 
      if ((steps+1) % (sample_step) == 0) {
            //    Dead   Hospital          Recovered        Infectious   Exposed
        P.push([ N*v[9], N*(v[5]+v[6]),  N*(v[7] + v[8]), N*v[2],    N*v[1] ])
        Iters.push(v)
        TI.push(N*(1-v[0]))
        // console.log((v[0] + v[1] + v[2] + v[3] + v[4] + v[5] + v[6] + v[7] + v[8] + v[9]))
        // console.log(v[0] , v[1] , v[2] , v[3] , v[4] , v[5] , v[6] , v[7] , v[8] , v[9])
      }
      v =integrate(method,f,v,t,dt); 
      t+=dt
    }
    return {"P": P, 
            "deaths": N*v[6], 
            "total": 1-v[0],
            "total_infected": TI,
            "Iters":Iters,
            "dIters": f}
  }

  function max(P, checked) {
    return P.reduce((max, b) => Math.max(max, sum(b, checked) ), sum(P[0], checked) )
  }

  $: Sol            = get_solution(dt, N, I0, R0, D_incbation, D_infectious, D_recovery_mild, D_hospital_lag, D_recovery_severe, D_death, P_SEVERE, CFR, InterventionTime, InterventionAmt, duration)
  $: P              = Sol["P"].slice(0,100)
  $: timestep       = dt
  $: tmax           = dt*100
  $: deaths         = Sol["deaths"]
  $: total          = Sol["total"]
  $: total_infected = Sol["total_infected"].slice(0,100)
  $: Iters          = Sol["Iters"]
  $: dIters         = Sol["dIters"]
  $: Pmax           = max(P, checked)
  $: lock           = false

  var colors = [ "#386cb0", "#8da0cb", "#4daf4a", "#f0027f", "#fdc086"]

  var Plock = 1

  var drag_y = function (){
    var dragstarty = 0
    var Pmaxstart = 0

    var dragstarted = function (d) {
      dragstarty = event.y  
      Pmaxstart  = Pmax
    }

    var dragged = function (d) {
      Pmax = Math.max( (Pmaxstart*(1 + (event.y - dragstarty)/500)), 10)
    }

    return drag().on("drag", dragged).on("start", dragstarted)
  }

  var drag_x = function (){
    var dragstartx = 0
    var dtstart = 0
    var Pmaxstart = 0
    var dragstarted = function (d) {
      dragstartx = event.x
      dtstart  = dt
      Plock = Pmax
      lock = true
    }
    var dragged = function (d) {
      dt = dtstart - 0.0015*(event.x - dragstartx)
    }
    var dragend = function (d) {
      lock = false
    }
    return drag().on("drag", dragged).on("start", dragstarted).on("end", dragend)
  }

  var drag_intervention = function (){
    var dragstarty = 0
    var InterventionTimeStart = 0

    var dragstarted = function (d) {
      dragstarty = event.x  
      InterventionTimeStart = InterventionTime
      Plock = Pmax
      lock = true
    }

    var dragged = function (d) {
      // InterventionTime = Math.max( (*(1 + (event.x - dragstarty)/500)), 10)
      // console.log(event.x)
      InterventionTime = Math.min(tmax-1, Math.max(0, InterventionTimeStart + xScaleTimeInv(event.x - dragstarty)))
    }

    var dragend = function (d) {
      lock = false
    }

    return drag().on("drag", dragged).on("start", dragstarted).on("end", dragend)
  }


  var drag_intervention_end = function (){
    var dragstarty = 0
    var durationStart = 0

    var dragstarted = function (d) {
      dragstarty = event.x  
      durationStart = duration
      Plock = Pmax
      lock = true
    }

    var dragged = function (d) {
      // InterventionTime = Math.max( (*(1 + (event.x - dragstarty)/500)), 10)
      // console.log(event.x)
      duration = Math.min(tmax-1, Math.max(0, durationStart + xScaleTimeInv(event.x - dragstarty)))
    }

    var dragend = function (d) {
      lock = false
    }

    return drag().on("drag", dragged).on("start", dragstarted).on("end", dragend)
  }


  $: parsed = "";
  onMount(async () => {
    var drag_callback_y = drag_y()
    drag_callback_y(selectAll("#yAxisDrag"))
    var drag_callback_x = drag_x()
    drag_callback_x(selectAll("#xAxisDrag"))
    var drag_callback_intervention = drag_intervention()
    // drag_callback_intervention(selectAll("#interventionDrag"))
    drag_callback_intervention(selectAll("#dottedline"))
    // var drag_callback_intervention_end = drag_intervention_end()
    // drag_callback_intervention_end(selectAll("#dottedline2"))

    if (typeof window !== 'undefined') {
      parsed = queryString.parse(window.location.search)
      if (!(parsed.logN === undefined)) {logN = parsed.logN}
      if (!(parsed.I0 === undefined)) {I0 = parseFloat(parsed.I0)}
      if (!(parsed.R0 === undefined)) {R0 = parseFloat(parsed.R0)}
      if (!(parsed.D_incbation === undefined)) {D_incbation = parseFloat(parsed.D_incbation)}
      if (!(parsed.D_infectious === undefined)) {D_infectious = parseFloat(parsed.D_infectious)}
      if (!(parsed.D_recovery_mild === undefined)) {D_recovery_mild = parseFloat(parsed.D_recovery_mild)}
      if (!(parsed.D_recovery_severe === undefined)) {D_recovery_severe = parseFloat(parsed.D_recovery_severe)}
      if (!(parsed.CFR === undefined)) {CFR = parseFloat(parsed.CFR)}
      if (!(parsed.InterventionTime === undefined)) {InterventionTime = parseFloat(parsed.InterventionTime)}
      if (!(parsed.InterventionAmt === undefined)) {InterventionAmt = parseFloat(parsed.InterventionAmt)}
      if (!(parsed.D_hospital_lag === undefined)) {D_hospital_lag = parseFloat(parsed.D_hospital_lag)}
      if (!(parsed.P_SEVERE === undefined)) {P_SEVERE = parseFloat(parsed.P_SEVERE)}
      if (!(parsed.Time_to_death === undefined)) {Time_to_death = parseFloat(parsed.Time_to_death)}

    }
  });

  function lock_yaxis(){
    Plock = Pmax
    lock  = true
  }

  function unlock_yaxis(){
    lock = false
  }

  const padding = { top: 20, right: 0, bottom: 20, left: 25 };

  let width  = 680;
  let height = 490;

  $: xScaleTime = scaleLinear()
    .domain([0, tmax])
    .range([padding.left, width - padding.right]);

  $: xScaleTimeInv = scaleLinear()
    .domain([0, width])
    .range([0, tmax]);

  $: indexToTime = scaleLinear()
    .domain([0, P.length])
    .range([0, tmax])

  window.addEventListener('mouseup', unlock_yaxis);

  $: checked = [true, false, false, true, true]
  $: active  = 0
  $: active_ = active >= 0 ? active : Iters.length - 1

  var Tinc_s = "\\color{#CCC}{T^{-1}_{\\text{inc}}} "
  var Tinf_s = "\\color{#CCC}{T^{-1}_{\\text{inf}}}"
  var Rt_s   = "\\color{#CCC}{\\frac{\\mathcal{R}_{t}}{T_{\\text{inf}}}} "
  $: ode_eqn = katex.renderToString("\\frac{d S}{d t}=-" +Rt_s +"\\cdot IS,\\qquad \\frac{d E}{d t}=" +Rt_s +"\\cdot IS- " + Tinc_s + " E,\\qquad \\frac{d I}{d t}=" + Tinc_s + "E-" + Tinf_s+ "I, \\qquad \\frac{d R}{d t}=" + Tinf_s+ "I", {
    throwOnError: false,
    displayMode: true,
    colorIsTextColor: true
  });

  function math_inline(str) {
    return katex.renderToString(str, {
    throwOnError: false,
    displayMode: false,
    colorIsTextColor: true
    });
  }

  function math_display(str) {
    return katex.renderToString(str, {
    throwOnError: false,
    displayMode: true,
    colorIsTextColor: true
    });
  }
  
  $: p_num_ind = 40

  $: get_d = function(i){
    return dIters(indexToTime(i), Iters[i])
  }

  function get_milestones(P){

    function argmax(x, index) {
      return x.map((x, i) => [x[index], i]).reduce((r, a) => (a[0] > r[0] ? a : r))[1];
    }

     //    Dead   Hospital          Recovered        Infectious   Exposed
    var milestones = []
    for (var i = 0; i < P.length; i++) {
      if (P[i][0] >= 0.5) {
        milestones.push([i*dt, "First death"])
        break
      }
    }

    var i = argmax(P, 1)
    milestones.push([i*dt, "Peak: " + format(",")(Math.round(P[i][1])) + " hospitalizations"])

    return milestones
  }

  $: milestones = get_milestones(P)
  $: log = true

</script>

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.css" integrity="sha384-bsHo4/LA+lkZv61JspMDQB9QP1TtO4IgOf2yYS+J6VdAYLVyx1c3XKcsHh0Vy8Ws" crossorigin="anonymous">

<style>
  .small { font: italic 6px Source Code Pro; }
  @import url('https://fonts.googleapis.com/css?family=Source+Code+Pro&display=swap');


  h2 {
    margin: auto;
    width: 950px;
    font-size: 40px;
    padding-top: 20px;
    padding-bottom: 20px;
    font-weight: 300;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    padding-bottom: 30px
  }

  .caption {
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    font-size: 13px;    
  }

  .paneltext{
    position:relative;
    height:130px;
  }

  .paneltitle{
    color:#777; 
    line-height: 17px; 
    padding-bottom: 4px;
    font-weight: 700;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
  }

  .paneldesc{
    color:#888; 
    text-align: left;
    font-weight: 300;
  }
    
  .range {
    width: 100%;
    padding: 0px;
    margin: 0px;
    margin-bottom: 0px;
  }

  .chart {
    width: 100%;
    margin: 0 auto;
    padding-top:0px;
    padding-bottom:10px;
    display: grid;
    grid-template-columns: 27% 1% 72%;
    grid-template-areas:
      'left-top    vline right'
      'left-bottom vline right';

  }

  .legend {
    color: #888;
    font-family: Helvetica, Arial;
    font-size: .725em;
    font-weight: 200;
    height: 100px;
    left: 20px;
    top: 4px;
    position: absolute;
  }

  .legendtitle {
    color:rgb(66,66,66); 
    font-size:13px;
    margin-bottom: 2px;
    font-weight: 600;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    text-transform: uppercase;
  }

  .legendblue {
    color:rgb(71, 129, 255);
    font-size:13px;
    margin-bottom: 2px;
    font-weight: 600;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    text-transform: uppercase;
  }

  .title{
    color:white; 
    font-size:16px;
    padding-bottom: 5px;
    font-weight: 300;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    line-height: 13px;
  }

  .bluetitle {
    font-weight: 300;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    margin-right: 0px;
    line-height:14px;
    font-weight: normal;
    text-align: left;
    color: rgb(71, 129, 255);
    border-bottom: 1px solid rgb(200,200,200);
    margin-bottom: 14px;
    margin-top: 20px;
    padding-bottom:5px;
    text-transform: uppercase;
    font-size: 14px
  }

  .legendtext{
    color:#888; 
    font-size:13px;
    padding-bottom: 6px;
    font-weight: 300;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    line-height: 15px;
  }

  .legendtextnum{
    color:#888; 
    font-size:13px;
    padding-bottom: 5px;
    font-weight: 300;
    line-height: 12px;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    left: -3px;
    position: relative;
  }

  .tick {
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    font-size: .725em;
    font-weight: 200;
    font-size: 13px
  }

  td { 
    text-align: left;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    border-bottom: 1px solid #DDD;
    border-collapse: collapse;
    padding: 3px;
    /*font-size: 13px;*/
  }

  tr {
    border-collapse: collapse;
    border-spacing: 15px;
  }

  .eqn {
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    margin: auto;
    display: flex;
    flex-flow: row wrap;
    width: 950px;
    column-count: 4;
    font-weight: 300;
    color:#666;
    font-size: 16.5px;
  }

  .adjustableslidertext {
    font-family: Pangram,Avenir,Helvetica,sans-serif;    
    background-color: rgb(221, 227, 243); 
    color: rgb(73, 129, 248);
    text-align: center;
    font-size: 13px;
    font-weight: bold;
    width: 85%; 
    margin-left: 10px; 
    border-radius: 10px;
  }

  label {
    padding-top: 10px;
  }

  th { font-weight: 500; text-align: left; padding-bottom: 5px; vertical-align: text-top;     border-bottom: 1px solid #DDD; }

  a:link { color: grey; }
  a:visited { color: grey; }

.grid-container {
  display: grid;
  grid-template-columns: 45% 38px 37%;
  grid-template-areas:
    'x11   x12   x13'
    'line1 line1 line1'
    'x21   x22   x23'
    'line2 line2 line2'
    'x31   x32   x33'
    'line3 line3 line3'
    'x41   x42   x43';
  grid-gap: 5px;
  position: relative;
}

.x11, .x21, .x31, .x41 {
  text-align: right;
  padding: 0px;
}
.x12, .x22, .x32, .x42{
  text-align: right;
  margin-left: 5px;
  margin-right: 5px;
}
.x13, .x23, .x33, .x43 {
  text-align: left;
  padding: 0px;
}
.line {
  margin-top: 0px;
  margin-bottom: 10px;
  border-bottom: 1px solid rgb(200,200,200);
}

.draggy:after {
    content:'';
    position: absolute;
    top: 98.5%;
    left: 50%;
    margin-left: -3px;
    width: 0;
    height: 0;
    border-top: solid 8px white;
    border-left: solid 8px transparent;
    border-right: solid 8px transparent;
}

.draggy2:after {
    content:'';
    position: absolute;
    top: 83%;
    left: 50%;
    margin-left: -3px;
    width: 0;
    height: 0;
    border-top: solid 8px rgb(200,200,200);
    border-left: solid 8px transparent;
    border-right: solid 8px transparent;
}
</style>

<div class="chart" style="width: 980px">

  <div style=" margin-right: 5px; grid-area: left-top">

    <div class="title" style="margin: auto; width:100%; margin-right: 20px; border-radius: 20px; padding: 4px; padding-top:7px; line-height:14px; font-weight: bold; text-align: center; background-color: rgb(82, 132, 247); margin-bottom: 20px">DAY {Math.round(indexToTime(active_))}</div>

    <div class="grid-container" style="width:100%;">

      <div class="x11" style="grid-area: x11;">
        <div class="legendtitle">Susceptible</div>
        <div class="legendtext">Population not immune to the virus</div>
      </div>
      <div class="x12" style="grid-area: x12;">
        <span style=""><Checkbox color="#CCC"/></span>
      </div>
      <div class="x13" style="position: relative; grid-area: x13">
        <div style="padding-top: 2px; padding-bottom: 1px">
          <div class="legendtextnum"> <span class="legendtitle"><b>{formatnumber(N*Iters[active_][0]/1000)}k</b></span>
                                  ({ (100*Iters[active_][0]).toFixed(1) }%)</div>
          <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[0]))}</span> / day </div>
          <div style="position: absolute; top: 19px">
            <Arrow height="36"/>
          </div>
        </div>
      </div>

      <div class="line" style="grid-area: line1;"></div>

      <div class="x21">
        <div class="legendtitle">Exposed</div>
        <div class="legendtext">Number of people incubating the virus</div>
      </div>
      <div class="x22">
        <span style=""><Checkbox color="{colors[4]}" bind:checked={checked[4]}/></span>
      </div>
      <div class="x23">
        <div style="position: relative; padding-top: 2px; padding-bottom: 1px">
          <div class="legendtextnum"> <i><span class="legendtitle"><b>{formatnumber(N*Iters[active_][1]/1000)}k</b></span>
                                  ({ (100*Iters[active_][1]).toFixed(2) }%)</div>
          <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[1])) }</span> / day
                                 </div>
          <div style="position: absolute; top: 19px">
            <Arrow height="36"/>
          </div>
        </div>
      </div>

      <div class="line" style="grid-area: line2;"></div>

      <div class="x31">
        <div class="legendtitle">Infectious</div>
        <div class="legendtext">Population that can transmit the virus</div>
      </div>
      <div class="x32">
        <span style=""><Checkbox color="{colors[3]}" bind:checked={checked[3]}/></span>
      </div>
      <div class="x33">
        <div style="position: relative; padding-top: 2px; padding-bottom: 1px">
          <div class="legendtextnum"> <span class="legendtitle"><b>{formatnumber(N*Iters[active_][2]/1000)}K</b></span>
                                  ({ (100*Iters[active_][2]).toFixed(2) }%)</div>
          <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[2])) }</span> / day
                                 </div>
        </div>
      </div>

      <div class="line" style="grid-area: line3;"></div>

      <div class="x31">
        <div class="legendtitle">Fatalities</div>
      </div>
      <div class="x32">
        <span style=""><Checkbox color="{colors[0]}" bind:checked={checked[0]}/></span>
      </div>
      <div class="x33">
        <div style="padding-top: 2px; padding-bottom: 1px">
          <div class="legendtextnum"> <span class="legendtitle"><b><i>{formatnumber(N*Iters[active_][9]/1000)}K </b></span>
                                  ({ (100*Iters[active_][9]).toFixed(2) }%)</div>
          <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[9])) }</span> / day
                                 </div>
        </div>
      </div>

    </div>
  </div>

  <div style=" margin-right: 5px; grid-area: left-bottom">

    <div class="bluetitle">Transmission Variables </div>

    <div style="width:100%;">

      <div>
        <div class="legendtext"><b>Basic reproduction</b> - number of people infected given by a given infectious individual</div>

        <div style="display:flex; justify-content: center;">
          <div style="width:58%;">
            <input class="range" type=range bind:value={R0} min=0.01 max=10 step=0.01> 
          </div>
          <div style="width:42%;">
            <div class="adjustableslidertext">
              {R0}
            </div>
          </div>
        </div>

      </div>


      <div>
        <div class="legendtext"><b>Incubation Period</b></div>

        <div style="display:flex; justify-content: center;">
          <div style="width:58%;">
            <input class="range" style="margin-bottom: 8px"type=range bind:value={D_incbation} min={0.15} max=24 step=0.0001>
          </div>
          <div style="width:42%;">
            <div class="adjustableslidertext">
              {(D_incbation).toFixed(2)} days
            </div>
          </div>
        </div>

      </div>

      <div>
        <div class="legendtext"><b>How long a patient is infectious</b></div>

        <div style="display:flex; justify-content: center;">
          <div style="width:58%;">
            <input class="range" type=range bind:value={D_infectious} min={0} max=24 step=0.01>
          </div>
          <div style="width:42%;">
            <div class="adjustableslidertext">
              {D_infectious} Days
            </div>
          </div>
        </div>

      </div>

    </div>

    <div class="bluetitle">Clinical Variables </div>

    <div style="width:100%;">

      <div>
        <div class="legendtext"><b>Fatality Rate</b></div>

        <div style="display:flex; justify-content: center;">
          <div style="width:58%;">
            <input class="range" style="margin-bottom: 8px" type=range bind:value={CFR} min={0} max=1 step=0.0001>
          </div>
          <div style="width:42%;">
            <div class="adjustableslidertext">
              {(CFR*100).toFixed(2)} %
            </div>
          </div>
        </div>

      </div>

      <div>
        <div class="legendtext"><b>Time from incubation to death</b></div>

        <div style="display:flex; justify-content: center;">
          <div style="width:58%;">
            <input class="range" type=range bind:value={Time_to_death} min={(D_infectious)+0.1} max=100 step=0.01>
          </div>
          <div style="width:42%;">
            <div class="adjustableslidertext">
              {Time_to_death} Days
            </div>
          </div>
        </div>

      </div>

    </div>
  </div>

  <div style="border-right:2.5px dotted rgb(200,200,200); grid-area: vline">
  </div>


  <div style="position:relative; grid-area: right">
    <div style="position:relative; height: {height+105}px; top:122px; left: 25px">

      <Chart bind:checked={checked}
             bind:active={active}
             y = {P} 
             xmax = {Xmax} 
             total_infected = {total_infected} 
             deaths = {deaths} 
             total = {total} 
             timestep={timestep}
             tmax={tmax}
             N={N}
             ymax={lock ? Plock: Pmax}
             InterventionTime={InterventionTime}
             colors={colors}
             log={!log}
             width={width}
             height={height-30}/>
      </div>

      <div id="xAxisDrag"
           style="pointer-events: all;
                  position: absolute;
                  top:{height+80}px;
                  left:{0}px;
                  width:{780}px;
                  background-color:#222;
                  opacity: 0;
                  height:25px;
                  cursor:col-resize">
      </div>

      <div id="yAxisDrag"
           style="pointer-events: all;
                  position: absolute;
                  top:{55}px;
                  left:{0}px;
                  width:{20}px;
                  background-color:#222;
                  opacity: 0;
                  height:425px;
                  cursor:row-resize">
      </div>

      <!-- Intervention Line -->
      <div style="position: absolute; width:{width+15}px; height: {height}px; position: absolute; top:100px; left:25px; pointer-events: none">
        <div id="dottedline"  style="pointer-events: all;
                    position: absolute;
                    top:-40px;
                    left:{xScaleTime(InterventionTime)}px;
                    visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
                    width:2px;
                    pointer-events: all;
                    cursor:col-resize;
                    height:{height+19}px">

        <div style="width:150px; 
                    position:relative; 
                    top:-65px; 
                    left: -80px; 
                    height: 140px; 
                    padding-right: 15px; 
                    cursor:col-resize; 
                    position:absolute;" >
        </div>

        </div>
      </div>

      <!-- Intervention Line slider -->
      <div style="position: absolute; width:{width+15}px; height: {height + 30}px; position: absolute; top:120px; left:25px; pointer-events: none">
        <div style="
            position: absolute;
            top:30px;
            left:{xScaleTime(InterventionTime)}px;
            visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
            width:2px;
            background-color:rgb(255, 255, 255, 0.5);
            border-right: 1px dashed rgb(0,0,0, 0.5);
            cursor:col-resize;
            height:{height-59}px">
            <div style="position:relative; top:-225px; left: -102px;" >
              <div class="caption draggy" style="pointer-events: none; 
                                          width: 180px; 
                                          position: absolute; 
                                          left:0; 
                                          top:90px; 
                                          height: 105px;
                                          padding: 5px 7px 7px 7px; 
                                          box-shadow: 0px 0px 5px rgb(0,0,0,0.1);
                                          background-color: white;
                                          border: 1px solid rgb(200,200,200);
                                          border-radius: 3px;">
                <div class="paneldesc"  style="position: absolute; text-align: center; width: 100px; left: 47px; top: -20px"> ← Drag Me →</div>  
                <div class="paneltext draggy2"  style="text-align: center;">
                  <div class="paneltitle" style="margin-top: 5px; padding-bottom:5px; margin-bottom: 5px; border-bottom: 2px dotted grey">Intervention day: <span style="color:red">{format("d")(InterventionTime)}</span></div>                
                  <div class="paneldesc" style="text-align:center; margin-bottom: 3px">Intervention effectiveness to decrease transmission by {OMInterventionAmt.toFixed(2)}%<br></div>
                  <div style="pointer-events: all">
                    <input class="range" type=range bind:value={OMInterventionAmt} min=0 max=1 step=0.01 on:mousedown={lock_yaxis}>
                  </div>
                </div>
              </div>
            </div>
          </div>
      </div>

    <div class="legendtext" style="width: 100%; margin-top: 5px; position:relative; padding: 10px">
      <div style="color:rgb(66,66,66); margin: 3px"><b>PRESETS</b></div>
      <div style="margin: 2px; padding: 5px; background-color: rgb(240,240,240); display: flex; text-transform: uppercase;">

        <div style="width: 20%; text-align:center">
          <label for="covid">COVID 19</label>
          <input type="radio" id="covid" name="age" value="0" on:change={presetParameters} checked>
        </div>

        <div style="width: 20%; text-align:center">
          <label for="h1n1">H1N1 Influenza</label>
          <input type="radio" id="h1n1" name="age" value="1" on:change={presetParameters}>
        </div>
  
        <div style="width: 20%; text-align:center">
          <label for="flu">Seasonal Flu</label>
          <input type="radio" id="flu" name="age" value="2" on:change={presetParameters}>
        </div>

        <div style="width: 20%; text-align:center">
          <label for="sars">SARS</label>
          <input type="radio" id="sars" name="age" value="3" on:change={presetParameters}>
        </div>

        <div style="width: 20%; text-align:center">
          <label for="ebola">Ebola</label>
          <input type="radio" id="ebola" name="age" value="4" on:change={presetParameters}>
        </div>        
  
      </div>
    </div>

  </div>


</div>

<!-- 
<div style="height:220px;">
  <div class="minorTitle">
    <div style="margin: 0px 0px 5px 4px" class="minorTitleColumn">Transmission Dynamics</div>
    <div style="flex: 0 0 20; width:20px"></div>
    <div style="margin: 0px 4px 5px 0px" class="minorTitleColumn">Clinical Dynamics</div>
  </div>
  <div class = "row">

    <div class="column">
      <div class="paneltitle">Population Inputs</div>
      <div class="paneldesc" style="height:30px">Size of population.<br></div>
      <div class="slidertext">{format(",")(Math.round(N))}</div>
      <input class="range" style="margin-bottom: 8px"type=range bind:value={logN} min={5} max=25 step=0.01>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px">Number of initial infections.<br></div>
      <div class="slidertext">{I0}</div>
      <input class="range" type=range bind:value={I0} min={1} max=10000 step=1>
    </div>

    <div class="column">
      <div class="paneltext">
      <div class="paneltitle">Basic Reproduction Number {@html math_inline("\\mathcal{R}_0")} </div>
      <div class="paneldesc">Measure of contagiousness: the number of secondary infections each infected individual produces. <br></div>
      </div>
      <div class="slidertext">{R0}</div>
      <input class="range" type=range bind:value={R0} min=0.01 max=10 step=0.01> 
    </div> 

    <div class="column">
      <div class="paneltitle">Transmission Times</div>
      <div class="paneldesc" style="height:30px">Length of incubation period, {@html math_inline("T_{\\text{inc}}")}.<br></div>
      <div class="slidertext">{(D_incbation).toFixed(2)} days</div>
      <input class="range" style="margin-bottom: 8px"type=range bind:value={D_incbation} min={0.15} max=24 step=0.0001>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px">Duration patient is infectious, {@html math_inline("T_{\\text{inf}}")}.<br></div>
      <div class="slidertext">{D_infectious} Days</div>
      <input class="range" type=range bind:value={D_infectious} min={0} max=24 step=0.01>
    </div>

    <div style="flex: 0 0 20; width:20px"></div>

    <div class="column">
      <div class="paneltitle">Mortality Statistics</div>
      <div class="paneldesc" style="height:30px">Case fatality rate.<br></div>
      <div class="slidertext">{(CFR*100).toFixed(2)} %</div>
      <input class="range" style="margin-bottom: 8px" type=range bind:value={CFR} min={0} max=1 step=0.0001>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px">Time from end of incubation to death.<br></div>
      <div class="slidertext">{Time_to_death} Days</div>
      <input class="range" type=range bind:value={Time_to_death} min={(D_infectious)+0.1} max=100 step=0.01>
    </div>

    <div class="column">
      <div class="paneltitle">Recovery Times</div>
      <div class="paneldesc" style="height:30px">Length of hospital stay<br></div>
      <div class="slidertext">{D_recovery_severe} Days</div>
      <input class="range" style="margin-bottom: 8px" type=range bind:value={D_recovery_severe} min={0.1} max=100 step=0.01>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px">Recovery time for mild cases<br></div>
      <div class="slidertext">{D_recovery_mild} Days</div>
      <input class="range" type=range bind:value={D_recovery_mild} min={0.5} max=100 step=0.01>
    </div>

    <div class="column">
      <div class="paneltitle">Care statistics</div>
      <div class="paneldesc" style="height:30px">Hospitalization rate.<br></div>
      <div class="slidertext">{(P_SEVERE*100).toFixed(2)} %</div>
      <input class="range" style="margin-bottom: 8px"type=range bind:value={P_SEVERE} min={0} max=1 step=0.0001>      
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px">Time to hospitalization.<br></div>
      <div class="slidertext">{D_hospital_lag} Days</div>
      <input class="range" type=range bind:value={D_hospital_lag} min={0.5} max=100 step=0.01>
    </div>

  </div>
</div> -->

