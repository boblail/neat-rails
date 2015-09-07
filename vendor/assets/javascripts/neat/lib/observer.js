/* Observer: this awesome class is described by The Grubbsian
   http://www.thegrubbsian.com/?p=100 */
/* modified to use prototype extensions */

var Observer = (function(){
  var Observation = function(name, func) {
    this.name = name;
    this.func = func;
  };
  var constructor = function() {
    this.observations = [];
  };
  constructor.prototype = {
    observe: function(name, func) {
      var exists = this.observations.find(function(i) {
        return (i.name==name) && (i.func==func);
      });
      if(!exists) {
        this.observations.push(new Observation(name, func));
      }
    },
    unobserve: function(name, func) {
      for(var i=0; i<this.observations.length;) {
        var observation = this.observations[i];
        if((observation.name==name) && (observation.func==func)) {
          this.observations.splice(i, 1);
        } else {
          i += 1;
        }
      }
    },
    fire: function(name, data, scope) {
      if(!(data instanceof Array)) data = [data];
      this.observations.each(function(i) {
        if(i.name == name) {
          i.func.apply(scope, data);
        }
      });
    }
  };
  return constructor;    
})();
