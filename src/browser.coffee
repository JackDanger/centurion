(($) ->

  Project = Backbone.Model.extend

  Projects = Backbone.Collection.extend

    model: Project
    url: '/projects'
    parse: (response, xhr) -> response.businesses

  projects = new Projects()

  ProjectView = Backbone.View.extend

    className: 'project'
    template: '#project-template'

    initialize: ->
      _.bindAll(this, 'render')
      this.model.bind('change', this.render)

      this.template = _.template($('#project-template').html())

    render: ->
      $(this.el).html(this.template(this.model.toJSON()))
      return this

  ProjectsView = Backbone.View.extend
    tagname: 'section'
    className: 'projects'
    template: '#projects-template'

    initialize: ->
      _.bindAll(this, 'render')
      this.template
      this.initializeTemplate()
      this.collection.bind('reset', this.render)

    render: ->

      collection = this.collection

      $(this.el).html(this.template({}))

      projects = this.$('.projects')
      collection.each (project) ->
        view = new ProjectView
          model: project,
          collection: collection
        $projects.append(view.render().el)
      this

    initializeTemplate: ->
      this.template = _.template($(this.template).html())

  Centurion = Backbone.Router.extend
    routes:
      '': 'home'
      'projects': 'projects'
      'projects/:name': 'project'
      'projects/:name/:file': 'file'

    initialize: ->
      this.projectsView = new ProjectsView
        collection: projects

    home: ->
      console.log this.projectsView.render().el
      content
        .empty()
        .append(this.projectsView.render().el)

    projects: ->
      content
        .empty()
        .text('projects')

    project: ->
      content
        .empty()
        .text('project')

    file: ->
      content
        .empty()
        .text('file')

  # OnReady
  $ ->

    window.App = new Centurion()
    window.content = $('#content')
    window.sidebar = $('#sidebar')
    Backbone.history.start()


)(jQuery)
