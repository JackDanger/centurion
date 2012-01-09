(function() {

  (function($) {
    var Centurion, Project, ProjectView, Projects, ProjectsView, projects;
    Project = Backbone.Model.extend;
    Projects = Backbone.Collection.extend({
      model: Project,
      url: '/projects',
      parse: function(response, xhr) {
        return response.businesses;
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
        $(this.el).html(this.template(this.model.toJSON()));
        return this;
      }
    });
    ProjectsView = Backbone.View.extend({
      tagname: 'section',
      className: 'projects',
      template: '#projects-template',
      initialize: function() {
        _.bindAll(this, 'render');
        this.template;
        this.initializeTemplate();
        return this.collection.bind('reset', this.render);
      },
      render: function() {
        var collection;
        collection = this.collection;
        $(this.el).html(this.template({}));
        projects = this.$('.projects');
        collection.each(function(project) {
          var view;
          view = new ProjectView({
            model: project,
            collection: collection
          });
          return $projects.append(view.render().el);
        });
        return this;
      },
      initializeTemplate: function() {
        return this.template = _.template($(this.template).html());
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
        return this.projectsView = new ProjectsView({
          collection: projects
        });
      },
      home: function() {
        console.log(this.projectsView.render().el);
        return content.empty().append(this.projectsView.render().el);
      },
      projects: function() {
        return content.empty().text('projects');
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
