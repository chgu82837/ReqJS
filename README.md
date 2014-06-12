ReqJS
===

require + request = Req => do many Request to Require XMLHTTP Resource and executes callbacks in queue as you desired

This one is a little bit like RequireJS which do request to get text resource from many place at once.

I accidentally made this because many NCHUSG projects need jQuery and bootstrap to work,and I want them to have all the same navigation bar.
With this, I can get all the resource required to make the bootstrap navigation bar work by only one script tag in html file

Usage
===

 1. put this line in your html file
  ```
  <script type="text/javascript" src="[to the req.js path]"></script>
  ```

 2. And call the Req function like this below will load all the default setting at once
  ```
  Req();
  ```

 3. The Req function has at most 4 parameters as shown below (also default setting which does the same thing as `Req();`):
  ```
  Req(
    // 1st parameter: reqs => an object containing some queues, key is their name
    {
      // one queue is an array containing some req objects
      'jsPoweredByJQuery': [
        
        // one req object at least should have url property which is the most important for XHR
        { 
          name: 'jQuery',
          url: '//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js',
          
          // type is also important, Req will process the result by the type value, more info is shown below
          type: 'js',
          
          // when success and queue to this req, this callback will be called.
          success: function(){ 
            return console.log("jquery OK!");
          },

          // when failed and queue to this req, this callback will be called.
          fail: function(){},
          
          // to check if this page already have the library you need, preventing to overwrite and load them again.
          // return true if passed tests then this request wont be sent (but success still will be called).
          test: function(){
            return (((typeof $) === 'function') && ((typeof $.fn.jquery) === 'string'));
          }
        },
        
        // another js that its callback wont be called until the previous req in the same array is finished. This is bootstrap requiring jquery.
        { 
          name: 'bootstrap',
          url: '//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js',
          type: 'js',
          success: function(){
            return console.log("bootstrap OK!");
          }
          // fail: function(){},
          
          // dont even create this key if you dont want to test
          // test: function(){},
        }
      ],

      // another queue which dont require jquery,this one is directly loaded
      'bootstrapCSS': [{
        //  name: optional
        // name : ""
        url: '//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css',
        type: 'css',
        success: function(){
          return console.log("bootstrapCSS OK!");
        }
        // fail callback: optional
        // fail: function(){},
      }]
    },
    
    // 2nd parameter: a callback when all queue is completed.
    whenCompleteAllReq,
    
    // 3rd parameter: boolean, true then display all the debug message
    info,

    // 4th parameter: boolean, true then you need to call [req instance].start() to start manually.
    dontFireAtOnce
    );
  ```
  
### types

 * js
  * create a script containing the result to the document. So you get the library after that~
 * css
  * create a style containing the result to the document. So you get the style sheet after that~~
 * json
  * its success callback's first parameter is the json result, json object wont be placed to any global variable or document.


Using Livescript
===
This js is scripted by Livescript and js file is the compiled result.
check the _src folder and true source file is there
