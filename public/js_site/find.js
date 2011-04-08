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

// stores the previous value of the find activation
// to detect if the value has really changed 
var prevVal = '';

// keeps a reference to the previous find request
// in order to make it abortable if a new request
// is issued before it is completed
var prevReq;

function doFind() {

 what = $('#find').val();
 
 if ( what != prevVal ) { // if the value has really changed ...
 
  prevVal = what;
  
  if ( what == '' ) { // there is nothing to find
    
   if ( prevReq ) { prevReq.abort(); } // terminate ongoing request if any
 
   $('div#found').html(''); // clear the visible results
   
  } else { // there is something to find

   if ( prevReq ) { prevReq.abort(); }  // terminate ongoing request if any
   
   // extract '/fi' or '/en' from the current URL to make find
   // language specific
   head = $(location).attr('pathname').toString().substring ( 0, 3 );
   
   // make the AJAX call to find service
   // store the reference to the call to prevReq    
   prevReq = $.ajax ({
    url: head + '/find/' + what + '/',
    success: function( data ){ // when te request completes this get executed
     
      prevReq = null; // clear the reference to this request
      prevVal = data; // store for comparison   
    
      $('div#found').html( data ); // update the visible results
     
    }  
   });
  
  }
    
 }

} 

$(document).ready(function() {

 $('#find').keyup(function() {
   doFind();
 });
 
 // intial rendering when page loads, important to bring
 // last content back up when returning to a page 
 doFind();


});