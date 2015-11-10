var Lail; if(!Lail) Lail={};
Lail.DelayedAction = function(callback, options) {
  // !todo: paste John Resig's code

  options = options || {};
  var self           = this,
      delay          = options.delay || 1000,
      steps          = options.steps || 10,
      intervalPeriod = delay / steps,
      counter        = 0,
      _params,
      _interval;

  this.trigger = function(params) {
    _params = params;
    restartCountdown();
  }

  function restartCountdown() {
    counter = steps;
    if(!_interval) {
      _interval = setInterval(countdown, intervalPeriod);
    }
  }

  function countdown() {
    if(counter > 0) {
      counter = counter - 1;
    } else {
      stopCountdown()
      fireCallback();
    }
  }

  function stopCountdown() {
    if(_interval) {
      clearInterval(_interval);
      _interval = null;
    }
  }

  function fireCallback() {
    try {
      callback(_params);
    } catch(e) {
      App.debug(e);
    }
  }
}
