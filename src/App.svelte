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

  let width  = 750;
  let height = 400;

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

  $: checked = [true, true, false, true, true]
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
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    padding-bottom: 30px
  }

  .center {
    margin: auto;
    width: 950px;
    padding-bottom: 20px;
    font-weight: 300;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    color:#666;
    font-size: 16.5px;
    text-align: justify;
    line-height: 24px
  }

  .ack {
    margin: auto;
    width: 950px;
    padding-bottom: 20px;
    font-weight: 300;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    color:#333;
    font-size: 13px;
  }

  .row {
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    margin: auto;
    display: flex;
    width: 948px;
    font-size: 13px;
  }

  .caption {
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    font-size: 13px;    
  }

  .column {
    flex: 158px;
    padding: 0px 5px 5px 0px;
    margin: 0px 5px 5px 5px;
    /*border-top: 2px solid #999*/
  }

  .minorTitle {
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    margin: auto;
    display: flex;
    width: 950px;
    font-size: 17px;
    color: #666;
  }

  .minorTitleColumn{
    flex: 60px;
    padding: 3px;
    border-bottom: 2px solid #999;
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
    font-family: nyt-franklin,helvetica,arial,sans-serif;
  }

  .paneldesc{
    color:#888; 
    text-align: left;
    font-weight: 300;
  }

  .slidertext{
    color:#555; 
    line-height: 7px; 
    padding-bottom: 0px; 
    padding-top: 7px;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    font-family: 'Source Code Pro', monospace;
    font-size: 10px;
    text-align: right;
    /*font-weight: bold*/
  }
    
  .range {
    width: 100%;
  }

  .chart {
    width: 100%;
    margin: 0 auto;
    padding-top:0px;
    padding-bottom:10px;
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
    color:#777; 
    font-size:13px;
    padding-bottom: 6px;
    font-weight: 600;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
  }


  .legendtext{
    color:#888; 
    font-size:13px;
    padding-bottom: 5px;
    font-weight: 300;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    line-height: 14px;
  }

  .legendtextnum{
    color:#888; 
    font-size:13px;
    padding-bottom: 5px;
    font-weight: 300;
    line-height: 12px;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    left: -3px;
    position: relative;
  }

  .tick {
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    font-size: .725em;
    font-weight: 200;
    font-size: 13px
  }

  td { 
    text-align: left;
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    border-bottom: 1px solid #DDD;
    border-collapse: collapse;
    padding: 3px;
    /*font-size: 14px;*/
  }

  tr {
    border-collapse: collapse;
    border-spacing: 15px;
  }

  .eqn {
    font-family: nyt-franklin,helvetica,arial,sans-serif;
    margin: auto;
    display: flex;
    flex-flow: row wrap;
    width: 950px;
    column-count: 4;
    font-weight: 300;
    color:#666;
    font-size: 16.5px;
  }

  th { font-weight: 500; text-align: left; padding-bottom: 5px; vertical-align: text-top;     border-bottom: 1px solid #DDD; }

  a:link { color: grey; }
  a:visited { color: grey; }

</style>

<h2>基于SEIR模型的疫情计算器</h2>

<div class="chart" style="display: flex; max-width: 1120px">

  <div style="flex: 0 0 270px; width:270px;">
    <div style="position:relative; top:48px; right:-115px">
      <div class="legendtext" style="position:absolute; left:-16px; top:-34px; width:50px; height: 100px; font-size: 13px; line-height:16px; font-weight: normal; text-align: center"><b>Day</b><br> {Math.round(indexToTime(active_))}</div>

      <!-- Susceptible -->
      <div style="position:absolute; left:0px; top:0px; width: 180px; height: 100px">

        <span style="pointer-events: none"><Checkbox color="#CCC"/></span>
        <Arrow height="41"/>

        <div class="legend" style="position:absolute;">
          <div class="legendtitle">易感人群</div>
          <div style="padding-top: 5px; padding-bottom: 1px">
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N*Iters[active_][0]))} 
                                  ({ (100*Iters[active_][0]).toFixed(2) }%)</i></div>
          <div class="legendtextnum"><span style="font-size:12px; padding-right:2px; color:#CCC">Δ</span> <i>{formatNumber(Math.round(N*get_d(active_)[0]))} / day</i>
                                 </div>
          </div>
        </div>
          <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 4px; position:relative;">人群对疾病没有免疫力</div>

      </div>

      <!-- Exposed -->
      <div style="position:absolute; left:0px; top:{legendheight*1}px; width: 180px; height: 100px">

        <Checkbox color="{colors[4]}" bind:checked={checked[4]}/>      
        <Arrow height="41"/>

        <div class="legend" style="position:absolute;">
          <div class="legendtitle">无症状感染者</div>

          <div style="padding-top: 5px; padding-bottom: 1px">
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N*Iters[active_][1]))} 
                                  ({ (100*Iters[active_][1]).toFixed(2) }%)</div>
          <div class="legendtextnum"><span style="font-size:12px; padding-right:2px; color:#CCC">Δ</span> <i>{formatNumber(Math.round(N*get_d(active_)[1])) } / day</i>
                                 </div>
          </div>
        </div>
        <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 4px; position:relative;">已接触病毒但不具有传染性(未发病)</div>

      </div>

      <!-- Infectious -->
      <div style="position:absolute; left:0px; top:{legendheight*2}px; width: 180px; height: 100px">

        <Checkbox color="{colors[3]}" bind:checked={checked[3]}/>
        <Arrow height="41"/>   

        <div class="legend" style="position:absolute;">
          <div class="legendtitle">感染者</div>
          <div style="padding-top: 5px; padding-bottom: 1px">
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N*Iters[active_][2]))} 
                                  ({ (100*Iters[active_][2]).toFixed(2) }%)</div>
          <div class="legendtextnum"><span style="font-size:12px; padding-right:2px; color:#CCC">Δ</span> <i>{formatNumber(Math.round(N*get_d(active_)[2])) } / day</i>
                                 </div>
          </div>
        </div>
        <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 4px; position:relative;"><i>活跃</i>的感染者</div>


      </div>

      <!-- Removed -->
      <div style="position:absolute; left:0px; top:{legendheight*3}px; width: 180px; height: 100px">

        <Checkbox color="grey" callback={(s) => {checked[1] = s; checked[0] = s; checked[2] = s} }/>
        <Arrow height="56" arrowhead="" dasharray="3 2"/>

        <div class="legend" style="position:absolute;">
          <div class="legendtitle">康复者</div>
          <div style="padding-top: 10px; padding-bottom: 1px">
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N* (1-Iters[active_][0]-Iters[active_][1]-Iters[active_][2]) ))} 
                                  ({ ((100*(1-Iters[active_][0]-Iters[active_][1]-Iters[active_][2]))).toFixed(2) }%)</div>
          <div class="legendtextnum"><span style="font-size:12px; padding-right:2px; color:#CCC">Δ</span> <i>{formatNumber(Math.round(N*(get_d(active_)[3]+get_d(active_)[4]+get_d(active_)[5]+get_d(active_)[6]+get_d(active_)[7]) )) } / day</i>
                                 </div>
          </div>
        </div>
        <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 4x; position:relative;">不再具有传染能力的人(康复/住院/死亡)</div>

      </div>

      <!-- Recovered -->
      <div style="position:absolute; left:0px; top:{legendheight*4+14-3}px; width: 180px; height: 100px">
        <Checkbox color="{colors[2]}" bind:checked={checked[2]}/>
        <Arrow height="23" arrowhead="" dasharray="3 2"/>
        <div class="legend" style="position:absolute;">
          <div class="legendtitle">康复</div>

          <div style="padding-top: 3px; padding-bottom: 1px">
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N*(Iters[active_][7]+Iters[active_][8]) ))} 
                                  ({ (100*(Iters[active_][7]+Iters[active_][8])).toFixed(2) }%)</div>
          </div>
        </div>
        <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 8px; position:relative;">完全康复</div>

      </div>

      <!-- Hospitalized -->
      <div style="position:absolute; left:0px; top:{legendheight*4+57}px; width: 180px; height: 100px">
        <Arrow height="43" arrowhead="" dasharray="3 2"/>
        <Checkbox color="{colors[1]}" bind:checked={checked[1]}/>
        <div class="legend" style="position:absolute;">
          <div class="legendtitle">住院人数</div>
          <div style="padding-top: 3px; padding-bottom: 1px">
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N*(Iters[active_][5]+Iters[active_][6]) ))} 
                                  ({ (100*(Iters[active_][5]+Iters[active_][6])).toFixed(2) }%)</div>
          </div>
          <div class="legendtextnum"><span style="font-size:12px; padding-right:2px; color:#CCC">Δ</span> <i>{formatNumber(Math.round(N*(get_d(active_)[5]+get_d(active_)[6]))) } / day</i>
                                 </div>
        </div>
        <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 10px; position:relative;">入院人数</div>

      </div>

      <div style="position:absolute; left:0px; top:{legendheight*4 + 120+2}px; width: 180px; height: 100px">
        <Arrow height="40" arrowhead="" dasharray="3 2"/>

        <Checkbox color="{colors[0]}" bind:checked={checked[0]}/>

        <div class="legend" style="position:absolute;">
          <div class="legendtitle">死亡人数</div>
          <div style="padding-top: 3px; padding-bottom: 1px">          
          <div class="legendtextnum"><span style="font-size:12px; padding-right:3px; color:#CCC">∑</span> <i>{formatNumber(Math.round(N*Iters[active_][9]))} 
                                  ({ (100*Iters[active_][9]).toFixed(2) }%)</div>
          <div class="legendtextnum"><span style="font-size:12px; padding-right:2px; color:#CCC">Δ</span> <i>{formatNumber(Math.round(N*get_d(active_)[9])) } / day</i>
                                 </div>
          </div>
        </div>
        <div class="legendtext" style="text-align: right; width:105px; left:-111px; top: 10px; position:relative;">死亡人数</div>
      </div>
    </div>
  </div>

  <div style="flex: 0 0 890px; width:890px; height: {height+128}px; position:relative;">

    <div style="position:relative; top:60px; left: 10px">
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
             log={!log}/>
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
      <div style="position: absolute; width:{width+15}px; height: {height}px; position: absolute; top:100px; left:10px; pointer-events: none">
        <div id="dottedline"  style="pointer-events: all;
                    position: absolute;
                    top:-38px;
                    left:{xScaleTime(InterventionTime)}px;
                    visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
                    width:2px;
                    background-color:#FFF;
                    border-right: 1px dashed black;
                    pointer-events: all;
                    cursor:col-resize;
                    height:{height+19}px">

        <div style="position:absolute; opacity: 0.5; top:-5px; left:10px; width: 120px">
        <span style="font-size: 13px">{@html math_inline("\\mathcal{R}_t=" + (R0*InterventionAmt).toFixed(2) )}</span> ⟶ 
        </div>

        {#if xScaleTime(InterventionTime) >= 100}
          <div style="position:absolute; opacity: 0.5; top:-2px; left:-97px; width: 120px">
          <span style="font-size: 13px">⟵ {@html math_inline("\\mathcal{R}_0=" + (R0).toFixed(2) )}</span>
          </div>      
        {/if}

        <div id="interventionDrag" class="legendtext" style="flex: 0 0 160px; width:120px; position:relative;  top:-70px; height: 60px; padding-right: 15px; left: -125px; pointer-events: all;cursor:col-resize;" >
          <div class="paneltitle" style="top:9px; position: relative; text-align: right">Intervention on day {format("d")(InterventionTime)}</div>
          <span></span><div style="top:9px; position: relative; text-align: right">
          (drag me)</div>
          <div style="top:43px; left:40px; position: absolute; text-align: right; width: 20px; height:20px; opacity: 0.3">
            <svg width="20" height="20">
              <g transform="rotate(90)">
                <g transform="translate(0,-20)">
                  <path d="M2 11h16v2H2zm0-4h16v2H2zm8 11l3-3H7l3 3zm0-16L7 5h6l-3-3z"/>
                 </g>  
              </g>
            </svg>
          </div>
        </div>


        <div style="width:150px; position:relative; top:-85px; height: 80px; padding-right: 15px; left: 0px; ;cursor:col-resize; background-color: white; position:absolute" >

        </div>


        </div>
      </div>

      <!-- Intervention Line slider -->
      <div style="position: absolute; width:{width+15}px; height: {height}px; position: absolute; top:120px; left:10px; pointer-events: none">
        <div style="
            position: absolute;
            top:-38px;
            left:{xScaleTime(InterventionTime)}px;
            visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
            width:2px;
            background-color:#FFF;
            border-right: 1px dashed black;
            cursor:col-resize;
            height:{height}px">
            <div style="flex: 0 0 160px; width:200px; position:relative; top:-125px; left: 1px" >
              <div class="caption" style="pointer-events: none; position: absolute; left:0; top:40px; width:150px; border-left: 2px solid #777; padding: 5px 7px 7px 7px; ">      
              <div class="paneltext"  style="height:20px; text-align: right">
              <div class="paneldesc">to decrease transmission by<br></div>
              </div>
              <div style="pointer-events: all">
              <div class="slidertext" on:mousedown={lock_yaxis}>{(100*(1-InterventionAmt)).toFixed(2)}%</div>
              <input class="range" type=range bind:value={OMInterventionAmt} min=0 max=1 step=0.01 on:mousedown={lock_yaxis}>
              </div>
              </div>
            </div>
          </div>
      </div>

<!-- 
      {#if xScaleTime(InterventionTime+duration) < (width - padding.right)}
        <div id="dottedline2" style="position: absolute; width:{width+15}px; height: {height}px; position: absolute; top:105px; left:10px; pointer-events: none;">
          <div style="
              position: absolute;
              top:-38px;
              left:{xScaleTime(InterventionTime+duration)}px;
              visibility: {(xScaleTime(InterventionTime+duration) < (width - padding.right)) ? 'visible':'hidden'};
              width:3px;
              background-color:white;
              border-right: 1px dashed black;
              cursor:col-resize;
              opacity: 0.3;
              pointer-events: all;
              height:{height+13}px">
            <div style="position:absolute; opacity: 0.5; top:-10px; left:10px; width: 120px">
            <span style="font-size: 13px">{@html math_inline("\\mathcal{R}_t=" + (R0*InterventionAmt).toFixed(2) )}</span> ⟶ 
            </div>
          </div>
        </div>

        <div style="position: absolute; width:{width+15}px; height: {height}px; position: absolute; top:120px; left:10px; pointer-events: none">
          <div style="
              opacity: 0.5;
              position: absolute;
              top:-38px;
              left:{xScaleTime(InterventionTime+duration)}px;
              visibility: {(xScaleTime(InterventionTime+duration) < (width - padding.right)) ? 'visible':'hidden'};
              width:2px;
              background-color:#FFF;
              cursor:col-resize;
              height:{height}px">
              <div style="flex: 0 0 160px; width:200px; position:relative; top:-125px; left: 1px" >
                <div class="caption" style="pointer-events: none; position: absolute; left:0; top:40px; width:150px; border-left: 2px solid #777; padding: 5px 7px 7px 7px; ">      
                <div class="paneltext"  style="height:20px; text-align: right">
                <div class="paneldesc">decrease transmission by<br></div>
                </div>
                <div style="pointer-events: all">
                <div class="slidertext" on:mousedown={lock_yaxis}>{(InterventionAmt).toFixed(2)}</div>
                <input class="range" type=range bind:value={InterventionAmt} min=0 max=1 step=0.01 on:mousedown={lock_yaxis}>
                </div>
                </div>
              </div>
            </div>
        </div>
      {/if} -->


      <div style="pointer-events: none;
                  position: absolute;
                  top:{height+84}px;
                  left:{0}px;
                  width:{780}px;
                  opacity: 1.0;
                  height:25px;
                  cursor:col-resize">
            {#each milestones as milestone}
              <div style="position:absolute; left: {xScaleTime(milestone[0])+8}px; top: -30px;">
                <span style="opacity: 0.3"><Arrow height=30 arrowhead="#circle" dasharray = "2 1"/></span>
                  <div class="tick" style="position: relative; left: 0px; top: 35px; max-width: 130px; color: #BBB; background-color: white; padding-left: 4px; padding-right: 4px">{@html milestone[1]}</div>
              </div>
            {/each}
      </div>
    
    <div style="opacity:{xScaleTime(InterventionTime) >= 192? 1.0 : 0.2}">
      <div class="tick" style="color: #AAA; position:absolute; pointer-events:all; left:10px; top: 10px">
        <Checkbox color="#CCC" bind:checked={log}/><div style="position: relative; top: 4px; left:20px">linear scale</div>
      </div>
    </div>

   </div>

</div>


<div style="height:220px;">
  <div class="minorTitle">
    <div style="margin: 0px 0px 5px 4px" class="minorTitleColumn" data-raw="Transmission Dynamics">传播动力学</div>
    <div style="flex: 0 0 20; width:20px"></div>
    <div style="margin: 0px 4px 5px 0px" class="minorTitleColumn">Clinical Dynamics</div>
  </div>
  <div class = "row">

    <div class="column">
      <div class="paneltitle" data-raw="Population Inputs">易感人群数</div>
      <div class="paneldesc" style="height:30px" data-raw="Size of population">(城市/社区)人口规模<br></div>
      <div class="slidertext">{format(",")(Math.round(N))}</div>
      <input class="range" style="margin-bottom: 8px"type=range bind:value={logN} min={5} max=25 step=0.01>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px" data-raw="Number of initial infections.">初始感染人数<br></div>
      <div class="slidertext">{I0}</div>
      <input class="range" type=range bind:value={I0} min={1} max=10000 step=1>
    </div>

    <div class="column">
      <div class="paneltext">
      <div class="paneltitle" data-raw="Basic Reproduction Number">基本再生数 {@html math_inline("\\mathcal{R}_0")} </div>
      <div class="paneldesc" data-raw="Measure of contagiousness: the number of secondary infections each infected individual produces.">传染性的衡量标准：每个感染者产生的二次感染的数量 <br></div>
      </div>
      <div class="slidertext">{R0}</div>
      <input class="range" type=range bind:value={R0} min=0.01 max=10 step=0.01> 
    </div> 

    <div class="column">
      <div class="paneltitle" data-raw="Transmission Times">传染期</div>
      <div class="paneldesc" style="height:30px" data-raw="Length of incubation period">潜伏期患者经过{@html math_inline("T_{\\text{inc}}")}天后成为感染者<br></div>
      <div class="slidertext">{(D_incbation).toFixed(2)} days</div>
      <input class="range" style="margin-bottom: 8px"type=range bind:value={D_incbation} min={0.15} max=24 step=0.0001>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px" data-raw="Duration patient is infectious">每个感染者在 {@html math_inline("T_{\\text{inf}}")}.<br></div>
      <div class="slidertext">{D_infectious} 天内具有传播力</div>
      <input class="range" type=range bind:value={D_infectious} min={0} max=24 step=0.01>
    </div>

    <div style="flex: 0 0 20; width:20px"></div>

    <div class="column">
      <div class="paneltitle" data-raw="Mortality Statistics">死亡率</div>
      <div class="paneldesc" style="height:30px" data-raw="Case fatality rate">病死率.<br></div>
      <div class="slidertext">{(CFR*100).toFixed(2)} %</div>
      <input class="range" style="margin-bottom: 8px" type=range bind:value={CFR} min={0} max=1 step=0.0001>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px" data-raw="Time from end of incubation to death">从感染(潜伏期)到死亡的天数.<br></div>
      <div class="slidertext">{Time_to_death} 天</div>
      <input class="range" type=range bind:value={Time_to_death} min={(D_infectious)+0.1} max=100 step=0.01>
    </div>

    <div class="column">
      <div class="paneltitle" data-raw="Recovery Times">恢复期</div>
      <div class="paneldesc" style="height:30px" data-raw="Length of hospital stay">住院时间<br></div>
      <div class="slidertext">{D_recovery_severe} 天</div>
      <input class="range" style="margin-bottom: 8px" type=range bind:value={D_recovery_severe} min={0.1} max=100 step=0.01>
      <div class="paneldesc" style="height:29px; border-top: 1px solid #EEE; padding-top: 10px" data-raw='Recovery time for mild cases'><br>恢复比率</div>
      <div class="slidertext">{D_recovery_mild} 天</div>
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
</div>

<div style="position: relative; height: 12px"></div>

<p class = "center">
At the time of writing, the coronavirus disease of 2019 remains a global health crisis of grave and uncertain magnitude. To the non-expert (such as myself), contextualizing the numbers, forecasts and epidemiological parameters described in the media and literature can be challenging. I created this calculator as an attempt to address this gap in understanding.
</p>

<p class = "center">
This calculator implements a classical infectious disease model &mdash <b><a href="https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology#The_SEIR_model">SEIR</a> </b>(<b>S</b>usceptible → <span style="color:{colors[4]}"><b>E</b></span>xposed → <span style="color:{colors[3]}"><b>I</b></span>nfected → <span><b>R</b></span>emoved), an idealized model of spread still used in frontlines of research e.g. [<a href="https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(20)30260-9/fulltext">Wu, et. al</a>, <a href = "https://cmmid.github.io/topics/covid19/current-patterns-transmission/wuhan-early-dynamics.html">Kucharski et. al</a>]. The dynamics of this model are characterized by a set of four ordinary differential equations that correspond to the stages of the disease's progression:
<span style="color:#777">{@html ode_eqn}</span>
In addition to the transmission dynamics, this model allows the use of supplemental timing information to model the death rate and healthcare burden. 
</p>

<p class = "center">
Note that one can use this calculator to measure one's risk exposure to the disease for any given day of the epidemic: the probability of getting infected on day {Math.round(indexToTime(active_))} given <a href="https://www.cdc.gov/coronavirus/2019-ncov/hcp/guidance-risk-assesment-hcp.html">close contact</a> with <input type="text" style="width:{Math.ceil(Math.log10(p_num_ind))*9.5 + 5}px; font-size: 15.5px; color:#777" bind:value={p_num_ind}> individuals is {((1-(Math.pow(1 - (Iters[active_][2])*(0.45/100), p_num_ind)))*100).toFixed(5)}% given an attack rate of 0.45% [<a href="https://www.cdc.gov/mmwr/volumes/69/wr/mm6909e1.htm?s_cid=mm6909e1_w">Burke et. al</a>].
</p>


<p class = "center">
A sampling of the estimates for epidemic parameters are presented below:
</p>

<div class="center">
<table style="width:100%; margin:auto; font-weight: 300; border-spacing: inherit">
  <tr>
    <th></th>
    <th>Location</th>
    <th>Reproduction Number<br> {@html math_inline("\\mathcal{R}_0")}</th>
    <th>Incubation Period<br> {@html math_inline("T_{\\text{inc}}")} (in days)</th>
    <th>Infectious Period<br> {@html math_inline("T_{\\text{inf}}")} (in days)</th>
  </tr>
  <tr>
    <td width="27%"><a href = "https://cmmid.github.io/topics/covid19/current-patterns-transmission/wuhan-early-dynamics.html">Kucharski et. al</a></td>
    <td>Wuhan </td>    
    <td>3.0 (1.5 — 4.5)</td>
    <td>5.2</td>
    <td>2.9</td>
  </tr>
  <tr>
    <td><a href = "https://www.nejm.org/doi/full/10.1056/NEJMoa2001316">Li, Leung and Leung</a></td>
    <td>Wuhan </td>    
    <td>2.2 (1.4 — 3.9)</td>
    <td>5.2 (4.1 — 7.0)</td>
    <td>2.3 (0.0 — 14.9)</td>
  </tr>
  <tr>
    <td><a href = "https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(20)30260-9/fulltext">Wu et. al</a></td>
    <td>Greater Wuhan </td>    
    <td>2.68 (2.47 — 2.86)</td>
    <td>6.1</td>
    <td>2.3</td>
  </tr>
  <tr>
    <td><a href = "https://www.who.int/news-room/detail/23-01-2020-statement-on-the-meeting-of-the-international-health-regulations-(2005)-emergency-committee-regarding-the-outbreak-of-novel-coronavirus-(2019-ncov)">WHO Initial Estimate</a></td>
    <td>Hubei </td>    
    <td>1.95 (1.4 — 2.5)</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td><a href = "https://www.who.int/docs/default-source/coronaviruse/who-china-joint-mission-on-covid-19-final-report.pdf">WHO-China Joint Mission </a></td>
    <td>Hubei </td>    
    <td>2.25 (2.0 — 2.5)</td>
    <td>5.5 (5.0 - 6.0)</td>
    <td></td>
  </tr>
  <tr>
    <td><a href = "https://www.biorxiv.org/content/10.1101/2020.01.25.919787v2">Liu et. al </a></td>
    <td>Guangdong</td>
    <td>4.5 (4.4 — 4.6)</td>
    <td>4.8 (2.2 — 7.4) </td>
    <td>2.9 (0 — 5.9)</td>
  </tr>
  <tr>
    <td><a href = "https://academic.oup.com/jtm/advance-article/doi/10.1093/jtm/taaa030/5766334">Rocklöv, Sjödin and Wilder-Smith</a></td>
    <td>Princess Diamond</td>
    <td>14.8</td>
    <td>5.0</td>
    <td>10.0</td>
  </tr>
  <tr>
    <td><a href = "https://www.eurosurveillance.org/content/10.2807/1560-7917.ES.2020.25.5.2000062">Backer, Klinkenberg, Wallinga</a></td>
    <td>Wuhan</td>
    <td></td>
    <td>6.5 (5.6 — 7.9)</td>
    <td></td>
  </tr>
  <tr>
    <td><a href = "https://www.medrxiv.org/content/10.1101/2020.01.23.20018549v2.article-info">Read et. al</a></td>
    <td>Wuhan</td>
    <td>3.11 (2.39 — 4.13)</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td><a href = "https://www.medrxiv.org/content/10.1101/2020.03.03.20028423v1">Bi et. al</a></td>
    <td>Shenzhen</td>
    <td></td>
    <td>4.8 (4.2 — 5.4)</td>
    <td>1.5 (0 — 3.4)</td>
    <td></td>
  </tr>

  <tr>
    <td><a href = "https://www.mdpi.com/2077-0383/9/2/462">Tang et. al</a></td>
    <td>China</td>
    <td>6.47 (5.71 — 7.23)</td>
    <td></td>
    <td></td>
  </tr>

</table>
</div>


<p class="center">
See [<a href="https://academic.oup.com/jtm/advance-article/doi/10.1093/jtm/taaa021/5735319">Liu et. al</a>] detailed survey of current estimates of the reproduction number. Parameters for the diseases' clinical characteristics are taken from the following <a href="https://www.who.int/docs/default-source/coronaviruse/who-china-joint-mission-on-covid-19-final-report.pdf">WHO Report</a>. 
</p>

<p class="center">
Please DM me feedback <a href="https://twitter.com/gabeeegoooh">here</a> or email me <a href="mailto:izmegabe@gmail.com">here</a>. My <a href="http://gabgoh.github.io/">website</a>.
</p>

<!-- 
<p class="center">
<a href="https://twitter.com/gabeeegoooh?ref_src=twsrc%5Etfw" class="twitter-follow-button" data-show-count="false"><script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</p> -->


<p class = "center">
<b> Model Details </b><br>
The clinical dynamics in this model are an elaboration on SEIR that simulates the disease's progression at a higher resolution, subdividing {@html math_inline("I,R")} into <i>mild</i> (patients who recover without the need for hospitalization), <i>moderate</i> (patients who require hospitalization but survive) and <i>fatal</i> (patients who require hospitalization and do not survive). Each of these variables follows its own trajectory to the final outcome, and the sum of these compartments add up to the values predicted by SEIR. Please refer to the source code for details. Note that we assume, for simplicity, that all fatalities come from hospitals, and that all fatal cases are admitted to hospitals immediately after the infectious period.
</p>

<p class = "center">
<b> Acknowledgements </b><br>
<a href = "https://enkimute.github.io/">Steven De Keninck</a> for RK4 Integrator. <a href="https://twitter.com/ch402">Chris Olah</a>, <a href="https://twitter.com/shancarter">Shan Carter
</a> and <a href="https://twitter.com/ludwigschubert">Ludwig Schubert
</a> wonderful feedback. <a href="https://twitter.com/NikitaJer">Nikita Jerschov</a> for improving clarity of text. Charie Huang for context and discussion.
</p>

<!-- Input data -->
<div style="margin-bottom: 30px">

  <div class="center" style="padding: 10px; margin-top: 3px; width: 925px">
    <div class="legendtext">Export parameters:</div>
    <form>
      <textarea type="textarea" rows="1" cols="5000" style="white-space: nowrap;  overflow: auto; width:100%; text-align: left" id="fname" name="fname">{state}</textarea>
    </form>
  </div>
</div>
