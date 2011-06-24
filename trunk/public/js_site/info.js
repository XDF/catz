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

// These variables contain all data needed to construct mailto
// links when page is loaded. The data is obfuscated to prevent
// spam bot harvesting as much as practically possible.

var catz_v00 = 'href';
var catz_v01 = 't';

var catz_v03 = 'n';
var catz_v04 = 'a';
var catz_v05 = 'catz';
var catz_v06 = '.';
var catz_v07 = ':';

var catz_v09 = 'mai';
var catz_v10 = 'fo';
var catz_v11 = 'in';

var catz_v13 = 'title';
var catz_v14 = '=';
var catz_v15 = '?';
var catz_v16 = 'subject';


function catzInfo() {

 // process elements that belong 
 // to class info or infox
 
 // set href of cat data mailto link
 $(catz_v06+catz_v11+catz_v10+'x').attr(
  catz_v00,catz_v09+'lto'+catz_v07+catz_v11+catz_v10+'@'+
  catz_v05+catz_v04+catz_v06+catz_v03+'e'+catz_v01+catz_v15+
  catz_v16+catz_v14+$(catz_v06+catz_v11+catz_v10+'x').attr(catz_v13)
 );

 // set content of cat data mailto link 
 $(catz_v06+catz_v11+catz_v10+'x').html(
  catz_v11+catz_v10+'@'+catz_v05+catz_v04+catz_v06+catz_v03+
  'e'+catz_v01
 );

 // change title of cat data mailto link
 $(catz_v06+catz_v11+catz_v10+'x').attr(
  catz_v13,catz_v11+catz_v10+'@'+catz_v05+
  catz_v04+catz_v06+catz_v03+'e'+catz_v01
 );

 // set href of info mail link
 $(catz_v06+catz_v11+catz_v10).attr(
  catz_v00,catz_v09+'lto'+catz_v07+catz_v11+catz_v10+'@'+
  catz_v05+catz_v04+catz_v06+catz_v03+'e'+catz_v01
 );

 // set title of info mailto link
 $(catz_v06+catz_v11+catz_v10).attr(
  catz_v13,catz_v11+catz_v10+'@'+catz_v05+
  catz_v04+catz_v06+catz_v03+'e'+catz_v01
 );

 // set content of info mail link 
 $(catz_v06+catz_v11+catz_v10).html(
  catz_v11+catz_v10+'@'+catz_v05+catz_v04+catz_v06+catz_v03+
  'e'+catz_v01
 );
 
}

$(document).ready(function() { 

 catzInfo();
   
});