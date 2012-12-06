// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require_self
//= require ./neat/lib/inflect
//= require ./neat/lib/paginated_list
//= require ./neat/lib/delayed_action
//= require ./neat/lib/jquery_extensions
//= require ./neat/collection_editor
//= require ./neat/model_editor

window.Neat = window.Neat || {}
window.Neat.debug = true;
window.Neat.logger = {
  log: function() {
    var log, __slice = [].slice, o, _ref;
    o = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (_ref = window.console).log.apply(_ref, o);
  }
};
