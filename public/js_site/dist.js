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

 // get the original address of the distribution image
 var jmapurl = $('#viz_dist').attr('src');

 // add json parameter to get the json destination instead 
 jmapurl = jmapurl.substring ( 0, jmapurl.length - 1 ) + '?jmap=1';
 
 //
 // can't get a simple redirect straight from the server due to
 // an open Firefox bug (open as 2011-10-27), must first fetch the
 // address from server and then request it separately (one more call)
 //
 // http://bugs.jquery.com/ticket/9155
 //
 
 $.get( jmapurl, function( jmapcont ) { 
 
  // if a decent repsonse
  if ( jmapcont.substring ( 0, 4 ) == 'http' ) {
  
   // the next call, now to the chart server and expection JSON
   $.getJSON ( jmapcont, function ( jdata ) {
  
   // if success, traverse the result and update the map areas
   
   $.each( jdata.chartshape, function ( i, l ) {
   
    $( '#map_dist_' + l.name ).attr( 'shape', l.type );
    $( '#map_dist_' + l.name ).attr( 'coords', l.coords );
   
   
   });  
    
  }); 
  
  }

 });

}
 
$(document).ready(function() { catzLoadDistMap(); }); 