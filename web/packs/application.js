import "core-js/stable";
import "regenerator-runtime/runtime";
require("turbolinks").start();
import 'bootstrap';


window.dataTables = [];
window.RequestsDataTables = [];
window.DraftsDataTables = [];
window.ArchivesDataTables = [];
window.AllDataTables = [];

require( 'datatables.net' )( window, $ );
require( 'datatables.net-bs4' )( window, $ );
require( 'datatables.net-buttons' )( window, $ );
require( 'datatables.net-buttons-bs4/js/buttons.bootstrap4.min' )( window, $ );
require('datatables.net-buttons/js/buttons.colVis.js')( window, $ );

import requests from './src/javascript/requests';
import all from './src/javascript/all';
import drafts from './src/javascript/drafts';
import archive from './src/javascript/archive';
import cvetool from './src/javascript/cvetool';

document.addEventListener("turbolinks:load", () => {
    requests.initDatatable();
    drafts.initDatatable();
    archive.initDatatable();
    cvetool.initDatatable();
    all.initDatatable();
});

document.addEventListener("turbolinks:before-cache", () => {
    requests.destroyDatatable();
    drafts.destroyDatatable();
    archive.destroyDatatable();
    cvetool.destroyDatatable();
    all.destroyDatatable();
});


// double shift press

var delta = 500;
var lastKeypressTime = 0;
function KeyHandler(event) {
    if ( event.ctrlKey ){
        var thisKeypressTime = new Date();
        if ( thisKeypressTime - lastKeypressTime <= delta ) {
            doDoubleKeypress();
            thisKeypressTime = 0;
        }
        lastKeypressTime = thisKeypressTime;
    }
}

function doDoubleKeypress() {
    if($('#large-quicksearch').length){
        $('#large-quicksearch').val('');
        $('#large-quicksearch').focus();
    }else if($('#quicksearch').length){
        $('#quicksearch').val('');
        $('#quicksearch').focus();
    }
}

// keyboard navigation is disabled for now
//document.addEventListener('keydown', KeyHandler);

