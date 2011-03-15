<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:variable name="devmap-js">
<![CDATA[
var req;
var map;
var doc;
var markers = new Array;

function load() {
    if (GBrowserIsCompatible()) {
        map = new GMap2(document.getElementById("map"));
        map.addControl(new GLargeMapControl());
        map.addControl(new GMapTypeControl());
        map.setCenter(new GLatLng(40.0, -38.0), 2);

        req = GXmlHttp.create();
        req.open("GET", "/proj/en/devrel/roll-call/devlist.xml?mode=yaml", true); 
        req.onreadystatechange = onGet;
        req.send(null); 
        window.setTimeout(function() {
          map.checkResize();
          }, 8000);
    }
}

function onGet() {
    if (req.readyState == 4) { 
        doc = eval("(" + req.responseText + ")");
        for (var x = 0; x < doc.developers.length; x++) {

            function createMarker(point) {
              var marker = new GMarker(point);
              GEvent.addListener(marker, "click", function() {
                  marker.openInfoWindowHtml(marker.text); 
                    });
              return marker;
                }
            
            var point = new GLatLng(doc.developers[x].lat, doc.developers[x].lon);
            var marker = new createMarker(point);
            marker.text =  "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN'"
                         + "  'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>"
                         + "<html xmlns='http://www.w3.org/1999/xhtml'>"
                         + "<head>"
                         + "<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>"
                         + "</head><body>"
                         + doc.developers[x].nick + "<br/>"
                         + "<b>" + doc.developers[x].name + "</b><br/>"
                         + "<i>" + doc.developers[x].roles + "</i></body></html>";
            marker.name = doc.developers[x].nick;
            markers.push(marker);
            map.addOverlay(marker);
        }

        var t = document.getElementById("devlinks");
        var selectDev = -1;
        var nCol = 8;
        var nLines = parseInt(markers.length / nCol);
        if (markers.length / nCol)
          ++nLines;
        for (var r = 0; r < nLines; ++r) {
          var tr = document.createElement("tr");
          for (var c = 0; c < nCol; ++c) {
            var td = document.createElement("td");
            var i = c * nLines + r;
            if (i < markers.length) {
              var a = document.createElement("a");
              if (markers[i].name == "X-PLACEHOLDER")
                selectDev = i;
              a.setAttribute("href", "javascript:markers["+i+"].openInfoWindowHtml(markers["+i+"].text)");
              a.textContent = markers[i].name;
              td.appendChild(a);
            }
            tr.appendChild(td);
          }
          t.appendChild(tr);
        }
        if (selectDev >= 0)
          markers[selectDev].openInfoWindowHtml(markers[selectDev].text);
    }
}
]]>
</xsl:variable>
</xsl:stylesheet>
