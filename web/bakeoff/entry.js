// No experiment module, hooks or variant state is loaded on the default path.
await import(new URLSearchParams(location.search).get('contextRing')==='1'?'./context-ring-entry.js':new URLSearchParams(location.search).get('spatialCells')==='1'?'./spatial-cells-entry.js':new URLSearchParams(location.search).get('sceneBudget')==='1'?'./scene-budget-entry.js':'./main.js');
