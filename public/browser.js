var Centurion, Project, ProjectList, ProjectListView, ProjectView, Source, SourceList;

Source = Backbone.Model.extend();

SourceList = Backbone.Collection.extend({
  model: Source,
  fetch: function() {
    var collection, mapper;
    collection = this;
    mapper = new RiakMapper(Riak, this.project.get('name'));
    mapper.map({
      source: function(data) {
        return [Riak.mapValuesJson(data)[0].file];
      }
    });
    mapper.reduce({
      source: function(filenames) {
        var file, seen, unique, _i, _len;
        seen = {};
        unique = [];
        for (_i = 0, _len = filenames.length; _i < _len; _i++) {
          file = filenames[_i];
          if (!seen[file]) {
            seen[file] = true;
            unique.push(file);
          }
        }
        return unique;
      }
    });
    return mapper.run(function(ok, filenames, xhr) {
      var files;
      files = _.map(filenames, function(filename) {
        return {
          filename: filename
        };
      });
      collection.add(files);
      return collection.project.trigger('changed');
    });
  }
});

Project = Backbone.Model.extend({
  initialize: function() {
    this.sourceList = new SourceList();
    return this.sourceList.project = this;
  }
});

ProjectView = Backbone.View.extend({
  className: 'project',
  template: '#project-template',
  model: Project,
  initialize: function() {
    this.template = _.template($('#project-template').html());
    this.model.sourceList.bind('add', this.render, this);
    return this.model.sourceList.fetch();
  },
  render: function() {
    var $element;
    console.log(JSON.stringify(this.model.sourceList.toJSON()));
    $element = $(this.el);
    $element.html(this.template({
      project: this.model.toJSON(),
      sourceList: this.model.sourceList.toJSON()
    }));
    return this;
  }
});

ProjectList = Backbone.Collection.extend({
  model: Project,
  url: '/riak?buckets=true',
  parse: function(response, xhr) {
    return _.map(response.buckets, function(bucket) {
      return {
        name: bucket
      };
    });
  }
});

ProjectListView = Backbone.View.extend({
  tagname: 'section',
  className: 'projects',
  template: '#projects-template',
  collection: ProjectList,
  initialize: function() {
    _.bindAll(this, 'render');
    this.template = _.template($(this.template).html());
    this.collection.bind('reset', this.render);
    return this.collection.fetch();
  },
  render: function() {
    var $element;
    $element = $(this.el);
    $element.html(this.template({
      projects: this.collection.toJSON()
    }));
    return this;
  }
});

Centurion = Backbone.Router.extend({
  routes: {
    '': 'home',
    'projects': 'projects',
    'projects/:name': 'project',
    'projects/:name/:source': 'source'
  },
  initialize: function() {},
  home: function() {
    var projectListView, template;
    projectListView = new ProjectListView({
      collection: new ProjectList()
    });
    template = _.template($("#home-template").html());
    content.empty().append(template());
    return sidebar.empty().append(projectListView.render().el);
  },
  projects: function() {
    var projectListView;
    projectListView = new ProjectListView({
      collection: new ProjectList()
    });
    return content.empty().append(projectListView.render().el);
  },
  project: function(name) {
    var projectView;
    projectView = new ProjectView({
      model: new Project({
        name: name
      })
    });
    return content.empty().append(projectView.render().el);
  },
  source: function() {
    return content.empty().text('source');
  }
});

$(function() {
  window.Riak = new RiakClient('/riak', '/mapred');
  window.App = new Centurion();
  window.content = $('#content');
  window.sidebar = $('#sidebar');
  return Backbone.history.start();
});
