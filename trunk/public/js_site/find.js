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

// stores the previous value of the find text
// to detect if the value has really changed 
var prevVal = '89435jklkasd83i89h3n5n23';

// keeps a reference to the previous find and sample requests
// in order to make them abortable if a new requests are issued
// before the previous ones have been completed
var prevReqFind;
var prevReqSample;

function doFind() {

 what = $('#find').val();
 
 if ( what != prevVal ) { // if the value has really changed ...
 
  prevVal = what;

  // terminate ongoing requests if any
  if ( prevReqFind ) { prevReqFind.abort(); }  
  if ( prevReqSample ) { prevReqSample.abort(); } 
  
  // extract '/fi' or '/en' from the current URL
  // to make find language sensitive
  var head = $(location).attr('pathname').toString().substring ( 0, 3 );
  
  if ( what == '' ) { // there is nothing to find

   // clear the find results
   $('div#found').html(''); 
       
   // load "anonymous" samples
   prevReqSample = $.ajax ({
    url: head + '/sample/',
    success: function( data ){ // when te request completes this get executed
     
      prevReqSample = null; // clear the reference to this request
      $('div#samples').html( data ); // update the result to DOM   
     
    }  
   });
    
  } else { // there is something to find
     
   prevReqFind = $.ajax ({
    url: head + '/find?what=' + what,
    success: function( data ){ // when te request completes this get executed
     
      prevReqFind = null; // clear the reference to this request
      $('div#found').html( data ); // update the visible results
     
    }  
   });

   prevReqSample = $.ajax ({
    url: head + '/sample?what=' + what,
    success: function( data ){ // when te request completes this get executed
     
      prevReqSample = null; // clear the reference to this request
      $('div#samples').html( data ); // update the result to DOM   
     
    }  
   });
  
  }
    
 }

} 

$(document).ready(function() {
 
 // intial rendering when page loads, important to bring
 // last content back up when returning to a page 
 doFind();

 // run every time there is a keyboard action on find field
 $('#find').keyup(function() {
  doFind();
 });

});