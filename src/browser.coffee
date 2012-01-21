

Source = Backbone.Model.extend()

SourceList = Backbone.Collection.extend
  model: Source
  fetch: () ->
    collection = this
    mapper = new RiakMapper Riak, this.project.get('name')
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
      files = _.map(filenames, (filename) -> {filename: filename})
      collection.add files
      collection.project.trigger('changed')


Project = Backbone.Model.extend
  initialize: ->
    this.sourceList = new SourceList()
    this.sourceList.project = this

ProjectView = Backbone.View.extend

  className: 'project'
  template: '#project-template'
  model: Project

  initialize: ->
    this.template = _.template $('#project-template').html()
    this.model.sourceList.bind 'add', this.render, this
    this.model.sourceList.fetch()

  render: ->
    console.log JSON.stringify(this.model.sourceList.toJSON())
    $element = $(this.el)
    $element.html this.template({
                    project: this.model.toJSON(),
                    sourceList: this.model.sourceList.toJSON()
                  })
    this

ProjectList = Backbone.Collection.extend

  model: Project
  url: '/riak?buckets=true'
  parse: (response, xhr) ->
    _.map response.buckets, (bucket) -> {name: bucket}

ProjectListView = Backbone.View.extend
  tagname: 'section'
  className: 'projects'
  template: '#projects-template'
  collection: ProjectList

  initialize: ->
    _.bindAll(this, 'render')
    this.template = _.template($(this.template).html())
    this.collection.bind('reset', this.render)
    this.collection.fetch()

  render: ->
    $element = $(this.el)
    $element.html(this.template({projects: this.collection.toJSON()}))
    this

Centurion = Backbone.Router.extend
  routes:
    '': 'home'
    'projects': 'projects'
    'projects/:name': 'project'
    'projects/:name/:source': 'source'

  initialize: ->

  home: ->
    projectListView = new ProjectListView
      collection: new ProjectList()
    template = _.template($("#home-template").html())
    content
      .empty()
      .append(template())
    sidebar
      .empty()
      .append(projectListView.render().el)

  projects: ->
    projectListView = new ProjectListView
      collection: new ProjectList()
    content
      .empty()
      .append(projectListView.render().el)

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

  Backbone.history.start()
  # this.projectsView = new ProjectsView
  #   collection: projects
  # projects.fetch()



