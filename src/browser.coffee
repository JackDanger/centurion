
getFiles = (projectName, callback) ->
  mapper = new RiakMapper Riak, this.name
  mapper.map source: (data) -> [Riak.mapValuesJson(data)[0].file]
  mapper.reduce
    source: (filenames) ->
      seen = {}
      unique = []
      for file in filenames
        unless seen[file]
          seen[file] = true
          unique.push file
      unique
  mapper.run (ok, filenames, xhr) ->
    callback _.map(filenames, (filename) -> {filename: filename})

Project = Backbone.Model.extend()

ProjectView = Backbone.View.extend

  className: 'project'
  template: '#project-template'
  model: Project

  initialize: ->
    this.template = _.template $('#project-template').html()

  render: ->
    $element = $(this.el)
    $element.html this.template(this.model.toJSON())
    this

Projects = Backbone.Collection.extend

  model: Project
  url: '/riak?buckets=true'
  parse: (response, xhr) ->
    _.map response.buckets, (bucket) -> {name: bucket}

ProjectsView = Backbone.View.extend
  tagname: 'section'
  className: 'projects'
  template: '#projects-template'
  collection: Projects

  initialize: ->
    _.bindAll(this, 'render')
    this.template = _.template($(this.template).html())
    this.collection.bind('reset', this.render)

  render: ->
    $element = $(this.el)
    $element.html(this.template({projects: this.collection}))
    this

Centurion = Backbone.Router.extend
  routes:
    '': 'home'
    'projects': 'projects'
    'projects/:name': 'project'
    'projects/:name/:source': 'source'

  initialize: ->

  home: ->
    projectsView = new ProjectsView
      collection: projects
    projects.fetch()
    template = _.template($("#home-template").html())
    content
      .empty()
      .append(template({project_size: projects.length}))
    sidebar
      .empty()
      .append(projectsView.render().el)

  projects: ->
    projectsView = new ProjectsView
      collection: projects
    projects.fetch()
    content
      .empty()
      .append(projectsView.render().el)

  project: (name) ->
    projectView = new ProjectView
      model: new Project({name: name})
    content
      .empty()
      .append(projectView.render().el)

  source: ->
    content
      .empty()
      .text('source')

# OnReady
$ ->
  window.Riak = new RiakClient '/riak', '/mapred'
  window.App = new Centurion()
  window.content = $('#content')
  window.sidebar = $('#sidebar')
  window.projects = new Projects()

  Backbone.history.start()
  # this.projectsView = new ProjectsView
  #   collection: projects
  # projects.fetch()



