//
// Catz - the world's most advanced cat show photo engine
// Copyright (c) 2010-2011 Heikki Siltala
// Licensed under The MIT License
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

function catzLoadDistMap() {

 // get the original unredirected address of the chart
 var jmapurl = $('#viz_dist').attr('src');

 // remember to remove the trailing slash
 // add a parameter to the end get the json data
 jmapurl = jmapurl.substring ( 0, jmapurl.length - 1 ) + '?jmap=1';
 
 // fetch the JSON data using $.ajax and dataType: 'text' 
 // instead of $.getJSON due to some issues on IE
  
 $.ajax ({ url: jmapurl, dataType: 'text', success: function ( data ) {
  
   // success
  
   var jdata = $.parseJSON( data );
    
  // remove the default map area set by the page    
   $( '#map_dist_default' ).remove();
   
   // push true image map coordinates to the predefined imagemap 
   $.each( jdata.chartshape, function ( i, l ) {
          
    $( '#map_dist_' + l.name ).attr( 'coords', l.coords );    
          
   });
          
 }});
  
}

 
$(document).ready(function() { catzLoadDistMap(); }); 