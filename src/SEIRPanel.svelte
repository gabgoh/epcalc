<script>

  import { format } from 'd3-format'
  import Checkbox from './Checkbox.svelte';
  import Arrow from './Arrow.svelte';

  export let Iters;
  export let N;
  export let colors;
  export let active_;
  export let checked;
  export let indexToTime;
  export let get_d;

  export let mobile = false

  function formatnumber(num) {
    if (num < 1/1000) {
      return "0"
    }
    if (num < 1) {
      return Math.round(num*1000)
    }
    return format(",.2s")(num*1000)
  }  

  function formatNumber(num) {
    return num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
  }

</script>

<style>

.legendblue {
  color:rgb(71, 129, 255);
  font-size:13px;
  margin-bottom: 2px;
  font-weight: 600;
  font-family: Pangram,Avenir,Helvetica,sans-serif;
  text-transform: uppercase;
}

.grid-container {
  display: grid;
  grid-template-columns: 45% 30px 39%;
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

.grid-container-mobile {
  display: grid;
  grid-template-columns: 43% 30px 41%;
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
  margin-bottom: 3px;
  border-bottom: 1px solid rgb(200,200,200);
}  


.title{
  color:white; 
  font-size:16px;
  padding-bottom: 5px;
  font-weight: 300;
  font-family: Pangram,Avenir,Helvetica,sans-serif;
  line-height: 13px;
}


.legendtext{
  color:#888; 
  font-size:13px;
  padding-bottom: 0px;
  font-weight: 300;
  font-family: Pangram,Avenir,Helvetica,sans-serif;
  line-height: 15px;
}

.legendtitle {
  color:rgb(66,66,66); 
  font-size:13px;
  margin-bottom: 2px;
  font-weight: 600;
  font-family: Pangram,Avenir,Helvetica,sans-serif;
  text-transform: uppercase;
}


.legendtitle {
  color:rgb(66,66,66); 
  font-size:13px;
  margin-bottom: 2px;
  font-weight: 600;
  font-family: Pangram,Avenir,Helvetica,sans-serif;
  text-transform: uppercase;
}


.legendtextnum{
  color:#888; 
  font-size:13px;
  padding-bottom: 6px;
  font-weight: 300;
  line-height: 12px;
  font-family: Pangram,Avenir,Helvetica,sans-serif;
  left: -3px;
  position: relative;
}

</style>

{#if !mobile}
<div class="title" style="margin: auto; width:100%; margin-right: 20px; border-radius: 20px; padding: 4px; padding-top:7px; line-height:14px; font-weight: bold; text-align: center; background-color: rgb(82, 132, 247); margin-bottom: 20px">DAY {Math.round(indexToTime(active_))}</div>
{:else}
<div class="title" style="margin: auto; margin-top: 5px; width:93%; border-radius: 3px; padding: 4px; padding-top:7px; line-height:14px; font-weight: bold; text-align: center; background-color: rgb(82, 132, 247); margin-bottom: 10px">DAY {Math.round(indexToTime(active_))}</div>
{/if}

<div class="{mobile ? 'grid-container-mobile': 'grid-container'}" style="width:100%;">

  <div class="x11" style="grid-area: x11;">
    <div class="legendtitle">Susceptible</div>
    {#if !mobile}
      <div class="legendtext">Population not immune to the virus</div>
    {:else}
      <div class="legendtext">Population not immune</div>
    {/if}
  </div>
  <div class="x12" style="grid-area: x12;">
    <span style=""><Checkbox color="#CCC"/></span>
  </div>
  <div class="x13" style="position: relative; grid-area: x13">
    <div style="padding-top: 2px; padding-bottom: 1px">
      <div class="legendtextnum"> <span class="legendtitle"><b>{formatnumber(N*Iters[active_][0]/1000)}</b></span>
                              ({ format(".3r")(100*Iters[active_][0]) }%)</div>
      <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[0]))}</span> per day </div>
      <div style="position: absolute; top: 19px">
        <Arrow height="25"/>
      </div>
    </div>
  </div>

  <div class="line" style="grid-area: line1;"></div>

  <div class="x21">
    <div class="legendtitle">Exposed</div>
    {#if !mobile}
      <div class="legendtext">Population incubating the virus</div>
    {:else}
      <div class="legendtext">Incubating the virus</div>
    {/if}
  </div>
  <div class="x22">
    <span style=""><Checkbox color="{colors[4]}" bind:checked={checked[4]}/></span>
  </div>
  <div class="x23">
    <div style="position: relative; padding-top: 2px; padding-bottom: 1px">
      <div class="legendtextnum"> <span class="legendtitle"><b>{formatnumber(N*Iters[active_][1]/1000)}</b></span>
                              ({ format(".1%")(Iters[active_][1]) })</div>
      <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[1])) }</span> per day
                             </div>
      <div style="position: absolute; top: 19px">
        <Arrow height="25"/>
      </div>
    </div>
  </div>

  <div class="line" style="grid-area: line2;"></div>

  <div class="x31">
    <div class="legendtitle">Infectious</div>
    {#if !mobile}
      <div class="legendtext">Population that can transmit the virus</div>
    {/if}

  </div>
  <div class="x32">
    <span style=""><Checkbox color="{colors[3]}" bind:checked={checked[3]}/></span>
  </div>
  <div class="x33">
    <div style="position: relative; padding-top: 2px; padding-bottom: 1px">
      <div class="legendtextnum"> <span class="legendtitle"><b>{formatnumber(N*Iters[active_][2]/1000)}</b></span>
                              ({ (100*Iters[active_][2]).toFixed(2) }%)</div>
      <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[2])) }</span> per day
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
      <div class="legendtextnum"> <span class="legendtitle"><b>{formatnumber(N*Iters[active_][9]/1000)} </b></span>
                              ({ (100*Iters[active_][9]).toFixed(2) }%)</div>
      <div class="legendtextnum"> <span class="legendblue">{formatNumber(Math.round(N*get_d(active_)[9])) }</span> per day
                             </div>
    </div>
  </div>

</div>