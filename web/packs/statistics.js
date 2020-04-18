
Taucharts = require( 'taucharts' );
require( 'taucharts/dist/plugins/tooltip' );



var chart = new Taucharts.Chart({
    type: 'horizontal-stacked-bar',
    y: 'type',
    x: 'count',
    color: 'stage',
    plugins: [Taucharts.api.plugins.get('tooltip')()],
    data: window.CHART_DATA,
});
chart.renderTo('#bar');
