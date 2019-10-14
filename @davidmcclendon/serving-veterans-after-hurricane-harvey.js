// https://observablehq.com/@davidmcclendon/serving-veterans-after-hurricane-harvey@273
export default function define(runtime, observer) {
  const main = runtime.module();

  main.variable(observer("chart")).define("chart", ["data","d3","width","height","drag","color","text_size","text_weight","text_visibility","invalidation"], function(data,d3,width,height,drag,color,text_size,text_weight,text_visibility,invalidation)
{
  
  const links = data.links.map(d => Object.create(d));
  const nodes = data.nodes.map(d => Object.create(d));
  
  const radiusScale = d3.scaleSqrt().domain([0,350]).range([1,20]);
  
  const simulation = d3.forceSimulation(nodes)
      .force("link", d3.forceLink(links).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(d => -300))
      .force("x", d3.forceX())
      .force("y", d3.forceY());

  const svg = d3.create("svg")
      .attr("viewBox", [-width / 2, -height / 2, width, height]);
      
  const rect = svg.append("rect")
      .attr("x", -width/2)
      .attr("y", -height/2)
      .attr("width","100%")
      .attr("height","100%")
      //.attr("viewBox", [-width, -height, width, height])
      .attr("fill","#fff");

  const link = svg.append("g")
      .attr("class", "links")
      .selectAll("line")
      .data(links)
      .join("line")
      .attr("stroke", "#999")
      .attr("stroke-opacity", 0.6)
      .attr("stroke-width", d => Math.sqrt(d.value));

  const node = svg.append("g")
      .attr("class", "nodes")
      .selectAll("g")
      .data(nodes)
      .enter()
      .append("g")
      .attr("class", "node")
      .call(drag(simulation));
  
  const circles = node.append("circle")
      .attr("r", d => radiusScale(d.num_clients))
      //.attr("fill-opacity", "0.7")
      .attr("fill", d => color(d.group));
  
  const labels = node.append("text")
      .text(d => d.id)
      .style("font-size", d => text_size(d.group))
      .style("font-weight", d => text_weight(d.group))
      .style("visibility", d => text_visibility(d.group))
      .attr('x', d => radiusScale(d.num_clients))
      .attr('y', 3);
  
  node.append("title")
      .text(d => d.id);

  simulation.on("tick", () => {
    link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

    node
        .attr("transform", d => `translate(${d.x}, ${d.y})`);
  });

  invalidation.then(() => simulation.stop());

  return svg.node();
}
);
  main.variable(observer()).define(["html"], function(html){return(
html`<style> 
body {
  font-family: "Georgia", serif;
}

text { 
  font-family: "Open Sans", sans-serif; 
  fill: #615A8A;
} 
</style>`
)});
  main.variable(observer("color")).define("color", function()
{
  const scale = ['#A00E26','#17163F'];
  return group => scale[group-1];
}
);
  main.variable(observer("text_size")).define("text_size", function()
{
  const scale = ['7px','10px'];
  return group => scale[group-1];
}
);
  main.variable(observer("text_weight")).define("text_weight", function()
{
  const scale = ['regular','bold'];
  return group => scale[group-1];
}
);
  main.variable(observer("text_visibility")).define("text_visibility", function()
{
  const scale = ['hidden','visible'];
  return group => scale[group-1];
}
);
  main.variable(observer("height")).define("height", function(){return(
600
)});
  main.variable(observer("drag")).define("drag", ["d3"], function(d3){return(
simulation => {
  
  function dragstarted(d) {
    if (!d3.event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }
  
  function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
  }
  
  function dragended(d) {
    if (!d3.event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
  
  return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
}
)});
  main.variable(observer("data")).define("data", ["d3"], function(d3){return(
d3.json("https://raw.githubusercontent.com/davidmcclendon/cax_network_graph/master/build/graphdata.json")
)});
  main.variable(observer("cola")).define("cola", ["require"], function(require){return(
require("webcola@3/WebCola/cola.min.js")
)});
  main.variable(observer("d3")).define("d3", ["require"], function(require){return(
require("d3@5")
)});
  return main;
}
