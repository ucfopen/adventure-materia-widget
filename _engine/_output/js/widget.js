(function() {
  Namespace('Adventure').Engine = (function() {
    var start, _drawQuestionScreen, _end, _init, _qset;

    _qset = null;
    start = function(instance, qset, version) {
      if (version == null) {
        version = '1';
      }
      _qset = qset;
      return _init(instance.name);
    };
    _init = function(title) {
      var data, screen;

      document.oncontextmenu = function() {
        return false;
      };
      document.addEventListener('mousedown', function(e) {
        if (e.button === 2) {
          return false;
        } else {
          return true;
        }
      });
      screen = $('#overview-screen-template').html();
      data = {
        title: title
      };
      $('#overview-screen').html(_.template(screen, data));
      return _drawQuestionScreen(_qset.items[0].items[0]);
    };
    _drawQuestionScreen = function(question) {
      var data, nodeScreen;

      nodeScreen = $('#node-screen-template').html();
      question = {
        text: question.questions[0].text
      };
      data = {
        question: question
      };
      return $('#node-screen').html(_.template(nodeScreen, data));
    };
    _end = function() {
      return Materia.Engine.end(true);
    };
    return {
      manualResize: true,
      start: start
    };
  })();

}).call(this);
