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


var catzMessInterval = 7;

function catzDemess( mess ) {

 var arr = mess.split('');
    
 var coll = '';
    
 var pos = catzMessInterval;
    
 while ( pos < arr.length ) {
    
  coll += arr[pos];    

  pos += catzMessInterval;
     
 }
     
 return coll;
 
}


function catzInfo() {

 // process elements that belong 
 // to class info or infox
 
 // extract '/fi' or '/en' from the current URL
 // to make info language sensitive
 var head = $(location).attr('pathname').toString().substring ( 0, 3 );

 $.ajax ({
  url: head + '/info/std/',
  success: function( data ) { // when the request completes this get executed
   
   plain = catzDemess ( data );

   if ( $('.info').length != 0 ) {    
    $('.info').html(plain);   
    $('.info').attr('href','mai' + 'lto:' + plain );
    $('.info').attr('title',plain );
   }
    
   if ( $('.infox').length != 0 ) {
    $('.infox').html(plain);   
    $('.infox').attr(
     'href', 'mai' + 'lto:' + plain + '?subject=' + 
     encodeURI ( $('.infox').attr('title') ) 
    );  
   }
   
  }
  
 });
   
}

$(document).ready(function() { 

 catzInfo();
   
});