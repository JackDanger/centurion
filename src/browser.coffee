(($) ->

  Project = Backbone.Model.extend
    initialize: (a,b) -> console.log 'initialized project', a,b

  Projects = Backbone.Collection.extend

    model: Project
    url: '/riak?buckets=true'
    parse: (response, xhr) ->
      console.log 'response: ', response, response.buckets
      _.map response.buckets, (bucket) -> {name: bucket}

  projects = new Projects()

  ProjectView = Backbone.View.extend

    className: 'project'
    template: '#project-template'

    initialize: ->
      _.bindAll(this, 'render')
      this.model.bind('change', this.render)

      this.template = _.template($('#project-template').html())

    render: ->
      console.log 'project/render: element', this.el, this.model
      console.log 'project/render: attributes', this.model.attributes
      console.log 'project/render: template', this.template(this.model.attributes)
      $(this.el).html(this.template(this.model.toJSON()))
      this

  ProjectsView = Backbone.View.extend
    tagname: 'section'
    className: 'projects'
    template: '#projects-template'
    collection: Projects

    initialize: ->
      console.log 'initializing ProjectsView', this.collection
      _.bindAll(this, 'render')
      this.template = _.template($(this.template).html())
      this.collection.bind('reset', this.render)

    render: ->
      $element = $(this.el)
      $element.html(this.template({projects: this.collection.toJSON()}))
      this

  Centurion = Backbone.Router.extend
    routes:
      '': 'home'
      'projects': 'projects'
      'projects/:name': 'project'
      'projects/:name/:file': 'file'

    initialize: ->
      this.projectsView = new ProjectsView
        collection: projects
      projects.fetch()

    home: ->
      this.projectsView.render().el
      console.log project.length
      template = _.template($("#home-template").html())
      content
        .empty()
        .append(template({project_size: projects.length}))
        .append(this.projectsView.render().el)

    projects: ->
      content
        .empty()
        .append(this.projectsView.render().el)

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
    # this.projectsView = new ProjectsView
    #   collection: projects
    # projects.fetch()



)(jQuery)
