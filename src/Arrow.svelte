<script>
export let height;
export let arrowhead = "#arrow"
export let dasharray = "3 2"
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
      <path d="M2,2 L10,6 L2,10 L6,6 L2,2" style="fill: rgb(71, 129, 255);"></path>
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
      <circle r="3" cx="3" cy="6" style="fill:rgb(71, 129, 255)"></circle>
    </marker>
  </defs>

</svg>

<div style="left:-1px; top:4px; width: 15px; height: {height}px; background-color: white; border-radius: 5px; top: 25px; opacity: 1.0; pointer-events: None">
<svg>
  <line x1="8" y1="0" x2="8" y2="{height-5}" stroke="rgb(71, 129, 255)" stroke-width="1.25" marker-end="url({arrowhead})" stroke-dasharray="{dasharray}" />
</svg>
</div>