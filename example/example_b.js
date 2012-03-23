(function(config) {
  for (var index = 0; index < 2; index++) {
    console.log('Message ' + index);
    console.log('Again! ' + index);
  }
  
  var object = {
    _name: function() {
      throw new Error('Oh noes!');
    }
  };
  
  try {
    object._nonesuch();
  } catch (e) {
    console.log(e.stack);
  }
  
  object._name();
})(window);
