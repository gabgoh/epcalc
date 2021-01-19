<script>
  export let color
  export let checked = false
  export let callback = () => {}
</script>

<div style="position: relative;
            width: 17px;
            height: 17px;
            background-color: {checked ? color:'white'};
            border-radius: 3px;
            opacity: 0.8;
            border: 2px solid {checked ? 'rgba(255,255,255,0)':color };
            box-shadow: inset 1px 1px 3px rgba(0, 0, 0, 0.1);
            user-select: none;
            "
      on:click={()=>{checked = !checked; callback(checked)}}>   
      <div style="cursor: default; font-size: 12px; left:2px; top:-1px; position: absolute; color:white">
    </div>
</div>
