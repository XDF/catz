//
// Catz - the world's most advanced cat show photo engine
// Copyright (c) 2010-2012 Heikki Siltala
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
var catzPrevValFind = '89435?2;:#jklOPIs7/)=)3IZ9h3n5n2X';

// stores the original value that gets then modified if not found
var catzCSSOrig = -1;

var catzCSSAttrib = 'background-color';

var catzCSSValue = '#FF7777';

// keeps a reference to the previous find request
// in order to make it abortable if a new request is issued
// before the previous one has been completed
var catzPrevReqFind;

function catzDoFind() {

 what = $('#find').val();
 
 if ( what != catzPrevValFind ) { // if the value has really changed ...
 
  catzPrevValFind = what;

  // terminate ongoing request if any
  if ( catzPrevReqFind ) { catzPrevReqFind.abort(); }  
  
  // extract langauge and setup from url
  var parts = 
   $(location).attr('pathname').toString().match('^/(..([1-9]{6})?)');
  
  var head = parts[0];
  
  if ( what == '' ) { // there is nothing to look for

   // clear the find results and hide the found
   $('div#found').html('');
   $('div#found').hide();
   $('#find').css(catzCSSAttrib,catzCSSOrig); 
           
  } else { // there is something to find, send request
     
   catzPrevReqFind = $.ajax ({
    url: head + '/find?s=' + encodeURI(what),
    success: function( data ){ // when te request completes this get executed
     
      catzPrevReqFind = null; // clear the reference to this request
      
      if ( data == '' ) {
       $('#find').css(catzCSSAttrib,catzCSSValue);
       $('div#found').html('');
       $('div#found').hide();      
      } else {
       $('#find').css(catzCSSAttrib,catzCSSOrig);
       $('div#found').html( data ); // update the visible results
       $('div#found').show(); // make them visible
      }
    }  
   });
     
  }
    
 }

} 

$(document).ready(function() {

 // store the original formatting for restore
 catzCSSOrig = $('#find').css(catzCSSAttrib);
  
 // intial rendering when page loads, to bring possible
 // previous content back up when returning to page
 catzDoFind();

 // run every time there is a keyboard action on find field
 $('#find').keyup(function() {
  catzDoFind();
 });

});