<script>

export let presetParameters;
export let align = "center"
export let mobile = false
</script>


{#if !mobile}
  <div style="color:rgb(66,66,66); margin: 3px"><b>PRESETS</b></div>
  <div style="margin: 2px; padding: 5px; border-radius: 3px; background-color: rgb(240,240,240); display: flex; flex-wrap: wrap; text-transform: uppercase;">

    <div style="width: 133px; text-align:{align}">
      <input type="radio" id="covid" name="age" value="0" on:change={presetParameters} checked>
      <label for="covid">COVID 19</label>
    </div>

    <div style="width: 152px; text-align:{align}">
      <input type="radio" id="h1n1" name="age" value="1" on:change={presetParameters}>
      <label for="h1n1">H1N1 Influenza</label>
    </div>

    <div style="width: 161px; text-align:{align}">
      <input type="radio" id="flu" name="age" value="2" on:change={presetParameters}>
      <label for="flu">Seasonal Flu</label>
    </div>

    <div style="width: 117px; text-align:{align}">
      <input type="radio" id="sars" name="age" value="3" on:change={presetParameters}>
      <label for="sars">SARS</label>
    </div>

    <div style="width: 128px; text-align:{align}">
      <input type="radio" id="ebola" name="age" value="4" on:change={presetParameters}>
      <label for="ebola">Ebola</label>
    </div>        
  </div>

{:else}

  <div style="margin: 2px; padding: 5px; border-radius: 3px; background-color: rgb(235,235,235); display: flex; flex-wrap: wrap; text-transform: uppercase; height: 240px">
  
    <div style="color:rgb(66,66,66); margin: 3px 3px 6px 3px; border-bottom: 1px solid rgb(180,180,180); width: 100%; height: 20px"><b>PRESETS</b></div>

    <div style="width: 138px; text-align:{align}; display: flex">
      <div><input type="radio" id="covid" name="age" value="0" on:change={presetParameters} checked></div>
      <div style="width: 80px; padding: 3.5px 4px 4px 4px"><label for="covid">COVID 19</label></div>
    </div>

    <div style="width: 138px; text-align:{align}; display: flex">
      <input type="radio" id="h1n1" name="age" value="1" on:change={presetParameters}>
      <div style="width: 80px; padding: 3.5px 4px 4px 4px"><label for="h1n1">H1N1 Influenza</label></div>
    </div>

    <div style="width: 138px; text-align:{align}; display: flex">
      <input type="radio" id="flu" name="age" value="2" on:change={presetParameters}>
      <div style="width: 80px; padding: 3.5px 4px 4px 4px"><label for="flu">Seasonal Flu</label></div>
    </div>

    <div style="width: 138px; text-align:{align}; display: flex">
      <input type="radio" id="sars" name="age" value="3" on:change={presetParameters}>
      <div style="width: 80px; padding: 3.5px 4px 4px 4px"><label for="sars">SARS</label></div>
    </div> 

    <div style="width: 138px; text-align:{align}; display: flex">
      <input type="radio" id="ebola" name="age" value="4" on:change={presetParameters}>
      <div style="width: 80px; padding: 3.5px 4px 4px 4px"><label for="ebola">Ebola</label></div>
    </div>        
  </div>
{/if}