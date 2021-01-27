<script>
export let value;
export let min
export let max
export let step
export let mousedown = () => {}
</script>

<style>
input[type=range] {
width: 100%;
margin: 0px 0px 0px 0px;
padding: 0px 0px 4px 0px;
-webkit-appearance: none;
}

input[type=range]::-webkit-slider-runnable-track {
background: #cfcfcf;
border: 0;
width: 100%;
height: 4px;
cursor: pointer;
}

input[type=range]::-webkit-slider-thumb {
margin-top: -5px;
width: 14px;
height: 14px;
background: #5284f6;
border: 2px solid #ffffff;
border-radius: 50px;
cursor: pointer;
-webkit-appearance: none;
}

input[type=range]:focus {
outline: none;
}
/*TODO: Use one of the selectors from https://stackoverflow.com/a/20541859/7077589 and figure out
how to remove the virtical space around the range input in IE*/
@supports (-ms-ime-align:auto) {
/* Pre-Chromium Edge only styles, selector taken from hhttps://stackoverflow.com/a/32202953/7077589 */
input[type=range] {
  margin: 0;
  /*Edge starts the margin from the thumb, not the track as other browsers do*/
}
}


</style>

<input class="range" 
	   type=range 
	   bind:value={value} 
	   min={min} 
	   max={max} 
	   step={step} 
	   on:mousedown={mousedown}>
