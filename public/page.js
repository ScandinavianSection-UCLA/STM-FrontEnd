// Generated by CoffeeScript 1.7.1
var appContext,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

require.config({
  paths: {
    jquery: "/components/jquery/jquery.min",
    bootstrap: "/components/bootstrap/dist/js/bootstrap.min",
    batman: "/batmanjs/batman",
    wordcloud: "/wordcloudjs/wordcloud"
  },
  shim: {
    bootstrap: {
      deps: ["jquery"]
    },
    batman: {
      deps: ["jquery"],
      exports: "Batman"
    },
    wordcloud: {
      exports: "WordCloud"
    }
  },
  waitSeconds: 30
});

appContext = void 0;

define("Batman", ["batman"], function(Batman) {
  return Batman.DOM.readers.batmantarget = Batman.DOM.readers.target && delete Batman.DOM.readers.target && Batman;
});

require(["jquery", "Batman", "wordcloud", "bootstrap"], function($, Batman, WordCloud) {
  var AppContext, STM, isScrolledIntoView;
  isScrolledIntoView = function(elem) {
    var elemTop;
    return (elemTop = $(elem).position().top) >= 0 && (elemTop + $(elem).height()) <= $(elem).parent().height();
  };
  AppContext = (function(_super) {
    __extends(AppContext, _super);

    function AppContext() {
      AppContext.__super__.constructor.apply(this, arguments);
      if (window.location.pathname === "/") {
        this.set("indexContext", new this.IndexContext);
      }
      if (window.location.pathname === "/topics") {
        this.set("topicsContext", new this.TopicsContext);
      }
    }

    AppContext.prototype.IndexContext = (function(_super1) {
      __extends(IndexContext, _super1);

      function IndexContext() {
        IndexContext.__super__.constructor.apply(this, arguments);
      }

      return IndexContext;

    })(Batman.Model);

    AppContext.prototype.TopicsContext = (function(_super1) {
      __extends(TopicsContext, _super1);

      TopicsContext.accessor("isCurrentTopicSelected", function() {
        return this.get("currentTopic") != null;
      });

      TopicsContext.accessor("filteredTopics", function() {
        var findInStr;
        findInStr = function(chars, str, j) {
          var idx, ret;
          if (j == null) {
            j = 0;
          }
          if (chars === "") {
            return [];
          }
          if ((idx = str.indexOf(chars[0])) === -1) {
            return;
          }
          if ((ret = findInStr(chars.slice(1), str.slice(idx + 1), idx + j + 1)) != null) {
            return [idx + j].concat(ret);
          }
        };
        return this.get("topics").map((function(_this) {
          return function(topic) {
            return {
              topic: topic,
              indices: findInStr(_this.get("topicSearch_text").toLowerCase(), topic.get("name").toLowerCase())
            };
          };
        })(this)).filter(function(x) {
          return x.indices != null;
        }).map((function(_this) {
          return function(topic, idx) {
            var c, i;
            return {
              topic: topic.topic,
              indices: topic.indices,
              active: idx === _this.get("topicsList_activeIndex"),
              html: ((function() {
                var _i, _len, _ref, _results;
                _ref = topic.topic.get("name");
                _results = [];
                for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
                  c = _ref[i];
                  if (__indexOf.call(topic.indices, i) >= 0) {
                    _results.push("<strong>" + c + "</strong>");
                  } else {
                    _results.push(c);
                  }
                }
                return _results;
              })()).join("")
            };
          };
        })(this));
      });

      function TopicsContext() {
        TopicsContext.__super__.constructor.apply(this, arguments);
        this.set("topicSearch_text", "");
        this.set("topicsList_activeIndex", 0);
        this.set("topics", []);
        $.ajax({
          url: "/data/topicsList",
          dataType: "jsonp",
          success: (function(_this) {
            return function(response) {
              return _this.set("topics", response.map(function(x) {
                return new _this.Topic(x);
              }));
            };
          })(this),
          error: function(request) {
            return console.error(request);
          }
        });
        $("#topicSearch").popover({
          html: true,
          animation: false,
          placement: "bottom",
          trigger: "focus",
          content: function() {
            return $("#topicsList");
          }
        }).on("hide.bs.popover", function() {
          return $("#hidden-content").append($("#topicsList"));
        });
      }

      TopicsContext.prototype.topicSearch_keydown = function(node, e) {
        var fl, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
        if ((_ref = e.which) === 13 || _ref === 27 || _ref === 38 || _ref === 40) {
          e.preventDefault();
        }
        switch (e.which) {
          case 13:
            $("#topicSearch").blur();
            if ((_ref1 = this.get("filteredTopics")[this.get("topicsList_activeIndex")]) != null) {
              if ((_ref2 = _ref1.topic) != null) {
                _ref2.onReady((function(_this) {
                  return function(err, topic) {
                    _this.set("currentTopic", topic);
                    _this.drawWordCloud();
                    return _this.drawPhraseCloud();
                  };
                })(this));
              }
            }
            this.set("topicSearch_text", (_ref3 = (_ref4 = this.get("filteredTopics")[this.get("topicsList_activeIndex")]) != null ? (_ref5 = _ref4.topic) != null ? _ref5.get("name") : void 0 : void 0) != null ? _ref3 : "");
            return this.set("topicsList_activeIndex", 0);
          case 27:
            return $("#topicSearch").blur();
          case 38:
            this.set("topicsList_activeIndex", ((fl = this.get("filteredTopics").length) + this.get("topicsList_activeIndex") - 1) % fl);
            if (!isScrolledIntoView("#topicsList a.list-group-item.active")) {
              return $("#topicsList a.list-group-item.active")[0].scrollIntoView(true);
            }
            break;
          case 40:
            this.set("topicsList_activeIndex", (this.get("topicsList_activeIndex") + 1) % this.get("filteredTopics").length);
            if (!isScrolledIntoView("#topicsList a.list-group-item.active")) {
              return $("#topicsList a.list-group-item.active")[0].scrollIntoView(false);
            }
        }
      };

      TopicsContext.prototype.topicSearch_input = function() {
        return this.set("topicsList_activeIndex", 0);
      };

      TopicsContext.prototype.drawWordCloud = function() {
        var wordsMax, wordsMin;
        wordsMax = Math.max.apply(Math, this.get("currentTopic").get("words").map(function(x) {
          return x.count;
        }));
        wordsMin = Math.min.apply(Math, this.get("currentTopic").get("words").map(function(x) {
          return x.count;
        }));
        return WordCloud($("#wordcloud")[0], {
          list: this.get("currentTopic").get("words").map(function(x) {
            return [x.word, (x.count - wordsMin + 1) / (wordsMax - wordsMin + 1) * 30 + 12];
          }),
          gridSize: 10,
          minRotation: -0.5,
          maxRotation: 0.5,
          rotateRatio: 0.2,
          ellipticity: 0.5,
          wait: 0,
          abort: function() {
            return console.error(arguments);
          }
        });
      };

      TopicsContext.prototype.drawPhraseCloud = function() {
        var phrasesMax, phrasesMin;
        phrasesMax = Math.max.apply(Math, this.get("currentTopic").get("phrases").map(function(x) {
          return x.count;
        }));
        phrasesMin = Math.min.apply(Math, this.get("currentTopic").get("phrases").map(function(x) {
          return x.count;
        }));
        return WordCloud($("#phrasecloud")[0], {
          list: this.get("currentTopic").get("phrases").map(function(x) {
            return [x.phrase, (x.count - phrasesMin + 1) / (phrasesMax - phrasesMin + 1) * 30 + 12];
          }),
          gridSize: 10,
          minRotation: -0.5,
          maxRotation: 0.5,
          rotateRatio: 0.2,
          ellipticity: 0.5,
          wait: 0,
          abort: function() {
            return console.error(arguments);
          }
        });
      };

      TopicsContext.prototype.gotoTopic = function(node) {
        var _ref, _ref1, _ref2;
        if ((_ref = this.get("topics").filter(function(x) {
          return x.get("id") === Number($(node).data("id"));
        })[0]) != null) {
          _ref.onReady((function(_this) {
            return function(err, topic) {
              _this.set("currentTopic", topic);
              _this.drawWordCloud();
              return _this.drawPhraseCloud();
            };
          })(this));
        }
        this.set("topicSearch_text", (_ref1 = (_ref2 = this.get("topics").filter(function(x) {
          return x.get("id") === Number($(node).data("id"));
        })[0]) != null ? _ref2.get("name") : void 0) != null ? _ref1 : "");
        return this.set("topicsList_activeIndex", 0);
      };

      TopicsContext.prototype.Topic = (function(_super2) {
        __extends(Topic, _super2);

        Topic.accessor("filteredRecords", function() {
          var _ref;
          return (_ref = this.get("records")) != null ? _ref.map((function(_this) {
            return function(record, idx) {
              return {
                record: record,
                active: record === _this.get("activeRecord")
              };
            };
          })(this)) : void 0;
        });

        function Topic(_arg) {
          var id, name;
          id = _arg.id, name = _arg.name;
          Topic.__super__.constructor.apply(this, arguments);
          this.set("id", id);
          this.set("name", name);
          this.set("isLoaded", false);
        }

        Topic.prototype.onReady = function(callback) {
          if (this.get("isLoaded")) {
            return callback(null, this);
          }
          return $.ajax({
            url: "/data/topicDetails",
            dataType: "jsonp",
            data: {
              id: this.get("id")
            },
            success: (function(_this) {
              return function(response) {
                _this.set("id", response.id);
                _this.set("name", response.name);
                _this.set("words", response.words);
                _this.set("phrases", response.phrases);
                _this.set("records", response.records.map(function(x) {
                  return new _this.Record(x);
                }));
                _this.set("isLoaded", true);
                return callback(null, _this);
              };
            })(this),
            error: function(request) {
              console.error(request);
              return callback(request);
            }
          });
        };

        Topic.prototype.gotoRecord = function(node) {
          var _ref;
          return (_ref = this.get("records").filter(function(x) {
            return x.get("article_id") === $(node).children("span").text();
          })[0]) != null ? _ref.onReady((function(_this) {
            return function(err, record) {
              return _this.set("activeRecord", record);
            };
          })(this)) : void 0;
        };

        Topic.prototype.Record = (function(_super3) {
          __extends(Record, _super3);

          Record.accessor("proportionPie", function() {
            var p;
            p = 100 * this.get("proportion");
            if (p > 99.99) {
              p = 99.99;
            }
            return "M 18 18\nL 18 3\nA 15 15 0 " + (p < 50 ? 0 : 1) + " 1 " + (18 + 15 * Math.sin(p * Math.PI / 50)) + " " + (18 - 15 * Math.cos(p * Math.PI / 50)) + "\nZ";
          });

          function Record(_arg) {
            var article_id, proportion;
            article_id = _arg.article_id, proportion = _arg.proportion;
            Record.__super__.constructor.apply(this, arguments);
            this.set("article_id", article_id);
            this.set("proportion", proportion);
            this.set("isLoaded", false);
          }

          Record.prototype.onReady = function(callback) {
            if (this.get("isLoaded")) {
              return callback(null, this);
            }
            return $.ajax({
              url: "/data/article",
              dataType: "jsonp",
              data: {
                article_id: this.get("article_id")
              },
              success: (function(_this) {
                return function(response) {
                  _this.set("article_id", response.article_id);
                  _this.set("article", response.article);
                  _this.set("isLoaded", true);
                  return callback(null, _this);
                };
              })(this),
              error: function(request) {
                console.error(request);
                return callback(request);
              }
            });
          };

          return Record;

        })(Batman.Model);

        return Topic;

      })(Batman.Model);

      return TopicsContext;

    })(Batman.Model);

    return AppContext;

  })(Batman.Model);
  STM = (function(_super) {
    __extends(STM, _super);

    function STM() {
      return STM.__super__.constructor.apply(this, arguments);
    }

    STM.appContext = appContext = new AppContext;

    return STM;

  })(Batman.App);
  STM.run();
  return $(function() {
    return appContext.set("pageLoaded", true);
  });
});
