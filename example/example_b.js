console.log('Hello from file B');

(function(config) {
  /* Log a few messages... */
  for (var index = 0; index < 2; index++) {
    console.log('Message ' + index);
    console.log('Again! ' + index);
  }
  
  var object = {
    /**
     * object#name -> undefined
     * @throws Error
     **/
    _name: function() {
      throw new Error('Oh noes!');
    }
  };
  
  // Find out where errors come from. We call something that throws an error
  // and console.log() the stack trace.
  try {
    object._nonesuch();
  } catch (e) {
    console.log(e.stack);
  }
  
  /*
  Then we can something else and let the browser deal with it.
  */
  object._name();
})(window);
