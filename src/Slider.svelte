<script>
export let value;
export let min
export let max
export let step
export let mousedown = () => {}
</script>

<style>


</style>

<input class="range" 
	   type=range 
	   bind:value={value} 
	   min={min} 
	   max={max} 
	   step={step} 
	   on:mousedown={mousedown}>
