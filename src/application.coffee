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
      container = $('#container')
      container
        .empty()
        .append(this.projectsView.render().el)

    projects: ->
      $('#container')
        .empty()
        .text('projects')

    project: ->
      $('#container')
        .empty()
        .text('project')

    file: ->
      $('#container')
        .empty()
        .text('file')

  # OnReady
  $ ->

    window.App = new Centurion()
    Backbone.history.start()

    # Geocode into an empty 'where' input
    if ($.trim($('#where').val()) == '')
      findMe()

    # search form uses Backbone
    $("form").submit ->
      projects.fetch()
      return false

)(jQuery)
