//
// Catz - the world's most advanced cat show photo engine
// Copyright (c) 2010-2011 Heikki Siltala
// Licensed under The MIT License
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and 8associated documentation files (the "Software"), to deal
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

var catzPrevSampleWidth = -1;

// keeps a reference to the previous sample request
// in order to make it abortable if a new request is issued
// before the previous one have been completed
var catzPrevReqSample;

function catzLoadSample() {

 // width down to tenths 
 var width = Math.floor ( $('#sample').width() / 10 ) * 10;
  
 if ( width > 2000 ) { width = 2000; }
 
 if ( width < 200 ) { width = 200; }
 
 if ( catzPrevSampleWidth != width ) {
  
  catzPrevSampleWidth = width;
  
  // extract '/fi' or '/en' from the current URL
  // to make samples language sensitive but without setup
  var head = $(location).attr('pathname').toString().substring ( 0, 3 );

  // terminate ongoing request if any
  if ( catzPrevReqSample ) { catzPrevReqSample.abort(); }  
  
  catzPrevReqSample = $.ajax ( {
 
   url: head + '/sample/' + width + '/',
  
   success: function( data ) {
  
     catzPrevReqSample = null; // clear the reference to this request
           
     $('#sample').html ( data );
                  
   },
   
   error: function () {
     
    $('#sample').html ( '' );
   
   }

  });

 }

}

$(document).ready(function() { // first activation on page load

 catzLoadSample();
   
});

$(window).resize(function() { // reactivation on every resize

 catzLoadSample(); 

});