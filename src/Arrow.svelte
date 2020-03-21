<script>
export let height;
export let arrowhead = "#arrow"
export let dasharray = "0 0"
</script>

<svg width="0" height="0">
  <defs>
    <marker
      id="arrow"
      markerUnits="strokeWidth"
      markerWidth="10"
      markerHeight="10"
      viewBox="0 0 12 12"
      refX="6"
      refY="6"
      orient="auto">
      <path d="M2,2 L10,6 L2,10 L6,6 L2,2" style="fill: grey;"></path>
    </marker>
  </defs>

  <defs>
    <marker
      id="circle"
      markerUnits="strokeWidth"
      markerWidth="10"
      markerHeight="10"
      viewBox="0 0 12 12"
      refX="6"
      refY="6"
      orient="auto">
      <circle r="3" cx="3" cy="6" style="fill:grey"></circle>
    </marker>
  </defs>

</svg>

<div style="position: absolute; left:-1px; top:4px; width: 15px; height: {height}px; background-color: none; border-radius: 5px; top: 25px; opacity: 0.8; pointer-events: None">
<svg>
  <line x1="8" y1="0" x2="8" y2="{height-5}"  stroke="grey" stroke-width="1.5" marker-end="url({arrowhead})" stroke-dasharray="{dasharray}" />
</svg>
</div>