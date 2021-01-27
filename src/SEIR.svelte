<script>
   
  import Chart from './Chart.svelte';
  import Control from './Control.svelte';
  import SEIRPanel from './SEIRPanel.svelte';
  import Selector from './Selector.svelte';
  import Slider from './Slider.svelte'

  import { scaleLinear } from "d3-scale";
  // import { Date } from "d3-time"
  import { onMount } from 'svelte';
  import { selectAll } from 'd3-selection'
  import { drag } from 'd3-drag';
  import queryString from "query-string";
  import { format } from 'd3-format'
  import { event } from 'd3-selection'
  import katex from 'katex';

  $: screenWidth = 0
  $: screenHeight = 0

  var sum = function(arr, bools){
    var x = 0
    for (var i = 0; i < arr.length; i++) {
      x = x + arr[i]*(bools[i] ? 1 : 0)
    }
    return x
  }

  function max(P, checked) {
    return P.reduce((max, b) => Math.max(max, sum(b, checked) ), sum(P[0], checked) )
  }

  export let Sol;
  export let OMInterventionAmt;
  export let InterventionTime = 100
  export let N;
  export let checked;

  $: P              = Sol["P"].slice(0,100)
  $: timestep       = Sol["dt"]
  $: tmax           = Sol["dt"]*100
  $: deaths         = Sol["deaths"]
  $: total          = Sol["total"]
  $: total_infected = Sol["total_infected"].slice(0,100)
  $: Iters          = Sol["Iters"]
  $: dIters         = Sol["dIters"]
  $: Pmax           = max(P, checked)
  $: lock           = false
  $: Xmax           = 110000

  export let colors;
  export let mobile

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

  function draggycallbacks() {
    var drag_callback_y = drag_y()
    drag_callback_y(selectAll("#yAxisDrag"))
    var drag_callback_x = drag_x()
    drag_callback_x(selectAll("#xAxisDrag"))
    var drag_callback_intervention = drag_intervention()
    // drag_callback_intervention(selectAll("#interventionDrag"))
    drag_callback_intervention(selectAll("#dottedline"))
    // var drag_callback_intervention_end = drag_intervention_end()
    // drag_callback_intervention_end(selectAll("#dottedline2"))
  }

  $: parsed = "";
  onMount(async () => {

    if (typeof window !== 'undefined') {
      
      draggycallbacks()

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

  export let width  = 680;
  export let height = 490;

  $: xScaleTime = scaleLinear()
    .domain([0, tmax])
    .range([padding.left, width - padding.right]);

  $: xScaleTimeInv = scaleLinear()
    .domain([0, width])
    .range([0, tmax]);

  window.addEventListener('mouseup', unlock_yaxis);

  export let active  = 0
  $: p_num_ind = 40

  $: log = true

</script>

<style>
  .small { font: italic 6px Source Code Pro; }
  @import url('https://fonts.googleapis.com/css?family=Source+Code+Pro&display=swap');

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

  .legendtext{
    color:#888; 
    font-size:13px;
    padding-bottom: 6px;
    font-weight: 300;
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    line-height: 15px;
  }

  .tick {
    font-family: Pangram,Avenir,Helvetica,sans-serif;
    font-size: .725em;
    font-weight: 200;
    font-size: 13px
  }

  label {
    padding-top: 10px;
  }

  a:link { color: grey; }
  a:visited { color: grey; }

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

  .draggymobile:after {
      content:'';
      position: absolute;
      top: 98%;
      left: 50%;
      margin-left: -3px;
      width: 0;
      height: 0;
      border-top: solid 6px white;
      border-left: solid 6px transparent;
      border-right: solid 6px transparent;
  }

  .draggymobile2:after {
      content:'';
      position: absolute;
      top: 113.5%;
      left: 50%;
      margin-left: -3px;
      width: 0;
      height: 0;
      border-top: solid 6px rgb(200,200,200);
      border-left: solid 6px transparent;
      border-right: solid 6px transparent;
  }

</style>

<div style="position:relative; top:{mobile ? 60: 122}px; left: 25px; height: {mobile ? height+35: height+105}px">

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
         space={mobile ? 0.5 : 1.5}
         displayday={mobile ? false : true}
         height={height-50}/>
  </div>

  {#if !mobile}

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
    <div style="position: absolute; width:{width+15}px; height: {height + 30}px; position: absolute; top:150px; left:25px; pointer-events: none">
      <div style="
          position: absolute;
          top:0px;
          left:{xScaleTime(InterventionTime)}px;
          visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
          width:2px;
          background-color:rgb(255, 255, 255, 0.5);
          border-right: 1px dashed rgb(0,0,0, 0.5);
          cursor:col-resize;
          height:{height-79}px">
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
              <div class="paneldesc"  style="position: absolute; text-align: center; width: 100px; left: 47px; top: -20px"> ← Drag →</div>  
              <div class="paneltext draggy2"  style="text-align: center;">
                <div class="paneltitle" style="margin-top: 5px; padding-bottom:5px; margin-bottom: 5px; border-bottom: 2px dotted grey">Day of intervention: <span style="color:red">{format("d")(InterventionTime)}</span></div>                
                <div class="paneldesc" style="text-align:center; margin-bottom: 3px">Intervention decreases transmission by <br> {100*OMInterventionAmt.toFixed(2)}%<br></div>
                <div style="pointer-events: all">
                  <Slider bind:value={OMInterventionAmt} min=0 max=1 step=0.01 mousedown={lock_yaxis}/>
                </div>
              </div>
            </div>
          </div>
        </div>
    </div>
  {:else}

    <!-- Intervention Line -->
    <div style="position: absolute; width:{width+15}px; height: {height}px; position: absolute; top:80px; left:25px; pointer-events: none;">
      <div id="dottedline"  style="pointer-events: all;
                  position: absolute;
                  top:-20px;
                  left:{xScaleTime(InterventionTime)}px;
                  visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
                  width:2px;
                  pointer-events: all;
                   /*background-color: black;*/
                  cursor:col-resize;
                  height:{height+19}px">

      <div style="width:150px; 
                  position:relative; 
                  /*background-color: black;*/
                  top:-65px; 
                  left: -80px; 
                  height: 90px;
                  padding-right: 15px; 
                  cursor:col-resize; 
                  position:absolute;" >
      </div>

      </div>
    </div>

    <!-- Intervention Line slider -->
    <div style="position: absolute; width:{width+15}px; height: {height + 30}px; position: absolute; top:35px; left:25px; pointer-events: none">
      <div style="
          position: absolute;
          top:30px;
          left:{xScaleTime(InterventionTime)}px;
          visibility: {(xScaleTime(InterventionTime) < (width - padding.right)) ? 'visible':'hidden'};
          width:2px;
          background-color:rgb(255, 255, 255, 0.5);
          border-right: 1px dashed rgb(0,0,0, 0.5);
          cursor:col-resize;
          height:{height-55}px">
          <div style="position:relative; top:-35px; left: {-102+56.5}px;" >
            <div class="caption draggymobile" style="pointer-events: none; 
                                        width: 74px; 
                                        position: absolute; 
                                        left:0; 
                                        top:-10px; 
                                        height: 42px;
                                        padding: 5px 7px 7px 7px; 
                                        background-color: white;
                                        border: 1px solid rgb(200,200,200);
                                        border-radius: 3px;">
              <div class="paneldesc"  style="position: absolute; font-size: 10px; text-align: center; width: 100px; left: -7px; top: -15px"> ← Drag →</div>  
              <div class="draggymobile2" style="text-align: center; line-height: 14px; padding: 0px; margin: 0px; color: black; top: -2px; position: relative; font-size: 12px">
                Day of Intervention* <div style="font-weight:bold; color:red; font-size:15px; margin-top: 4px">{format("d")(InterventionTime)}</div>
              </div>
            </div>
          </div>
        </div>
    </div>

  {/if}



