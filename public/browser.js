var Centurion, Project, ProjectView, Projects, ProjectsView, getFiles;

getFiles = function(projectName, callback) {
  var mapper;
  mapper = new RiakMapper(Riak, this.name);
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
    return callback(_.map(filenames, function(filename) {
      return {
        filename: filename
      };
    }));
  });
};

Project = Backbone.Model.extend();

ProjectView = Backbone.View.extend({
  className: 'project',
  template: '#project-template',
  model: Project,
  initialize: function() {
    return this.template = _.template($('#project-template').html());
  },
  render: function() {
    var $element;
    $element = $(this.el);
    $element.html(this.template(this.model.toJSON()));
    return this;
  }
});

Projects = Backbone.Collection.extend({
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

ProjectsView = Backbone.View.extend({
  tagname: 'section',
  className: 'projects',
  template: '#projects-template',
  collection: Projects,
  initialize: function() {
    _.bindAll(this, 'render');
    this.template = _.template($(this.template).html());
    return this.collection.bind('reset', this.render);
  },
  render: function() {
    var $element;
    $element = $(this.el);
    $element.html(this.template({
      projects: this.collection
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
    var projectsView, template;
    projectsView = new ProjectsView({
      collection: projects
    });
    projects.fetch();
    template = _.template($("#home-template").html());
    content.empty().append(template({
      project_size: projects.length
    }));
    return sidebar.empty().append(projectsView.render().el);
  },
  projects: function() {
    var projectsView;
    projectsView = new ProjectsView({
      collection: projects
    });
    projects.fetch();
    return content.empty().append(projectsView.render().el);
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
  window.projects = new Projects();
  return Backbone.history.start();
});
