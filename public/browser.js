(function() {

  (function($) {
    var Centurion, Project, ProjectView, Projects, ProjectsView, projects;
    Project = Backbone.Model.extend({
      initialize: function(a, b) {
        return console.log('initialized project', a, b);
      }
    });
    Projects = Backbone.Collection.extend({
      model: Project,
      url: '/riak?buckets=true',
      parse: function(response, xhr) {
        console.log('response: ', response, response.buckets);
        return _.map(response.buckets, function(bucket) {
          return {
            name: bucket
          };
        });
      }
    });
    projects = new Projects();
    ProjectView = Backbone.View.extend({
      className: 'project',
      template: '#project-template',
      initialize: function() {
        _.bindAll(this, 'render');
        this.model.bind('change', this.render);
        return this.template = _.template($('#project-template').html());
      },
      render: function() {
        console.log('project/render: element', this.el, this.model);
        console.log('project/render: attributes', this.model.attributes);
        console.log('project/render: template', this.template(this.model.attributes));
        $(this.el).html(this.template(this.model.toJSON()));
        return this;
      }
    });
    ProjectsView = Backbone.View.extend({
      tagname: 'section',
      className: 'projects',
      template: '#projects-template',
      collection: Projects,
      initialize: function() {
        console.log('initializing ProjectsView', this.collection);
        _.bindAll(this, 'render');
        this.template = _.template($(this.template).html());
        return this.collection.bind('reset', this.render);
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
        'projects/:name/:file': 'file'
      },
      initialize: function() {
        this.projectsView = new ProjectsView({
          collection: projects
        });
        return projects.fetch();
      },
      home: function() {
        var template;
        this.projectsView.render().el;
        console.log(project.length);
        template = _.template($("#home-template").html());
        return content.empty().append(template({
          project_size: projects.length
        })).append(this.projectsView.render().el);
      },
      projects: function() {
        return content.empty().append(this.projectsView.render().el);
      },
      project: function() {
        return content.empty().text('project');
      },
      file: function() {
        return content.empty().text('file');
      }
    });
    return $(function() {
      window.App = new Centurion();
      window.content = $('#content');
      window.sidebar = $('#sidebar');
      return Backbone.history.start();
    });
  })(jQuery);

}).call(this);
