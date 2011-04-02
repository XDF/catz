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

var prevVal = '';

var prevReq;

function doSuggest() {

 what = $('#find').val();
 
 if ( what != prevVal ) {
 
  prevVal = what;
  
  if ( what == '' ) {
 
   if ( prevReq ) { prevReq.abort(); }
 
   $('div#suggest').html('');
   
  } else {

   if ( prevReq ) { prevReq.abort(); }

   prevReq = $.ajax ({
    url: 'http://localhost:3000/en/suggest/' + what + '/',
    success: function( data ){
     
      prevReq = null;
      prevVal = data;  
    
      $('div#suggest').html( data );
     
    }  
   });
  
  }
    
 }

} 

$(document).ready(function() {

 // for non-js browsing samples are hidden by style sheet
 // now set them visible 
 $('div#suggest').css( "display", "inline" );

 $('#find').keyup(function() {
   doSuggest();
 });
 
 // intial rendering when page loads, important to bring
 // last content up when returning to page 
 doSuggest();


});