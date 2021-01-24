<script>
   
  import Chart from './Chart.svelte';
  import Control from './Control.svelte';
  import SEIRPanel from './SEIRPanel.svelte';
  import Selector from './Selector.svelte';
  import SEIR from './SEIR.svelte'
  import { scaleLinear } from "d3-scale";

  var colors = [ "#386cb0", "#8da0cb", "#4daf4a", "#f0027f", "#fdc086"]

  function presetParameters(event) {
    const i = event.currentTarget.value
    const params = 
    [{R0: 3.0, D_incbation: 5.5, D_infectious: 9.0/2, CFR: 0.5/100, Time_to_death: 19},
     {R0: 1.5, D_incbation: 2.5, D_infectious: 8.9/2, CFR: 0.02/100, Time_to_death: 12},
     {R0: 1.3, D_incbation: 2, D_infectious: 7.0/2, CFR: 0.05/100, Time_to_death: 14},
     {R0: 2.5, D_incbation: 6.4, D_infectious: 15/2, CFR: 9.6/100, Time_to_death: 17.4},
     {R0: 1.7, D_incbation: 10, D_infectious: 7/2, CFR: 53/100,  Time_to_death: 8}]

    R0 = params[i].R0
    D_incbation = params[i].D_incbation
    D_infectious = params[i].D_infectious
    CFR = params[i].CFR
    Time_to_death = params[i].Time_to_death
  }

  var active = 0
  $: screenWidth = 0
  $: screenHeight = 0
  let mobile = false

  $: lock = false

  $: checked = [true, false, false, true, true]

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
  let InterventionTime  = 100
  $: OMInterventionAmt = 2/3
  $: InterventionAmt   = 1 - OMInterventionAmt
  $: Time              = 220
  $: dt                = 2
  $: P_SEVERE          = 0.2
  $: duration          = 7*12*1e10

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
            "dt": dt*interpolation_steps,
            "dIters": f}
  }

  $: Sol = get_solution(dt, N, I0, R0, D_incbation, D_infectious, D_recovery_mild, D_hospital_lag, D_recovery_severe, D_death, P_SEVERE, CFR, InterventionTime, InterventionAmt, duration)


  $: indexToTime = scaleLinear()
    .domain([0, 100])
    .range([0, Sol["dt"]*100])

  $: get_d = function(i){
    return Sol["dIters"](indexToTime(i), Sol["Iters"][i])
  }

</script>

<style>

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

  .chartmobile {
    margin: 0 auto;
    padding-top:0px;
    padding-bottom:10px;
    display: grid;
    grid-gap: 10px;
    grid-template-columns: 253px 118px;
    grid-template-areas:
      'top         top'
      'line        line'
      'left-bottom right-bottom'
      'line2        line2';
  }


  .legendtext{
    color:#888; 
    font-size:13px;
    padding-bottom: 6px;
    font-weight: 300;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    line-height: 15px;
  }

</style>

<svelte:window bind:innerWidth={screenWidth} bind:innerHeight={screenHeight}/>

<div style="padding: 5px">
<input type="checkbox" bind:checked={mobile} checked> Mobile = {mobile}
</div>

{#if !mobile}
  <meta name="viewport" content="width=980">
  <div class="chart" style="width: 980px">

    <div style=" margin-right: 5px; grid-area: left-top">

      <SEIRPanel Iters={Sol["Iters"]} 
                 N={N}
                 colors={colors}
                 active_={active >= 0 ? active : Sol['Iters'].length - 1} 
                 indexToTime={indexToTime}
                 get_d={get_d}
                 bind:checked={checked} />

    </div>


    <div style=" margin-right: 5px; grid-area: left-bottom">

      <Control bind:R0={R0}
               bind:D_incbation={D_incbation}
               bind:D_infectious={D_infectious}
               bind:CFR={CFR}
               bind:Time_to_death={Time_to_death}/>

    </div>

    <div style="border-right:2.5px dotted rgb(200,200,200); grid-area: vline">
    </div>


    <div style="position:relative; grid-area: right">

      <SEIR colors={colors} Sol={Sol} N={N} height={480} width={680} bind:OMInterventionAmt bind:InterventionTime bind:checked bind:active/>
   
      <div class="legendtext" style="width: 100%; margin-top: 20px; position:relative; padding: 10px">
        <Selector presetParameters={presetParameters}/>
      </div>

    </div>

  </div>

{:else}

  <meta name="viewport" content="width=400">
  <div class="chartmobile" style="width: 381px">

    <div style="position:relative; grid-area: top; left:-20px;">
      <SEIR colors={colors}
            Sol={Sol}
            N={N}
            height={280}
            width={365}
            bind:mobile
            bind:OMInterventionAmt
            bind:InterventionTime
            bind:checked
            bind:active/>
    </div> 

    <div style="grid-area: line; border-bottom: 1px solid rgb(200,200,200)"></div>

    <div style="grid-area: left-bottom; padding: 2px 15px 0px 0px">
      <SEIRPanel Iters={Sol["Iters"]} 
                 N={N}
                 colors={colors}
                 active_={active >= 0 ? active : Sol['Iters'].length - 1} 
                 indexToTime={indexToTime}
                 get_d={get_d}
                 bind:checked={checked}
                 mobile={true} />

    </div>

    <div class="legendtext" style="width: 100%; margin-top: 5px; position:relative; grid-area: right-bottom">
      <Selector presetParameters={presetParameters} align="left" mobile={true}/>
    </div>

    <div style="grid-area: line2; border-bottom: 1.5px solid rgb(200,200,200)"></div>

  </div>

{/if}
