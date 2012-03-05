Chart = {
  commits: (project, commits) ->
    commits = _.map commits.models, (commit) -> commit.attributes
    commits = _.sortBy commits, (commit) -> commit.date
    Chart.flog project, commits
    Chart.flogAverage project, commits

  flog: (project, commits) ->
    options =
      legend:
        enabled: false
      chart:
        defaultSeriesType: 'spline'
        renderTo: 'flogChart'
      title:
        text: 'total complexity of '+project.get('name')
      subtitle:
        text: commits.length + ' commits'
      xAxis:
        type: ''
        dateTimeLabelFormats:
          month: (a,b) ->
            console.log a, b
            '%e. %b'
          year: '%b'
      yAxis:
        title:
          text: 'Total complexity'
        min: 0
      tooltip:
        formatter: ->
          commit = this.point.config[2]
          '<b>' + this.series.name + '</b><br/>' +
          Highcharts.dateFormat('%e. %b', new Date(1000 * commit.date)) +
          ': ' + Chart.withCommas(parseInt(this.y)) +
          '<br>' + commit.comment.replace("\n", "<br/>")
      series: [{
          name: '<b>Flog</b> complexity total'
          color: '#F24',
          data: _.map commits, (commit, idx) -> [commit.date, commit.flog, commit]
        }]
    window.chart = new Highcharts.Chart options

  flogAverage: (project, commits) ->
    options =
      legend:
        enabled: false
      chart:
        type: 'spline'
        renderTo: 'flogAverageChart'
      title:
        text: 'average method complexity of '+project.get('name')
      subtitle:
        text: commits.length + ' commits'
      yAxis:
        title:
          text: 'Average method complexity'
        min: 0
      xAxis:
        type: 'datetime'
        dateTimeLabelFormats:
          month: '%e. %b'
          year: '%b'
      tooltip:
        formatter: ->
          commit = this.point.config[2]
          '<b>' + this.series.name + '</b><br/>' +
          Highcharts.dateFormat('%e. %b', new Date(1000 * commit.date)) +
          ': ' + Chart.withCommas(parseInt(this.y)) +
          '<br>' + commit.comment.replace("\n", "<br/>")
      commits: commits
      series: [{
          name: '<b>Flog</b> method complexity average'
          color: '#454',
          data: _.map commits, (commit) -> [commit.date, commit.flogAverage, commit]
        }]
    new Highcharts.Chart options

  withCommas: (number) ->
    halves = number.toString().split('.')
    integer = halves[0]
    decimal = if halves[1] then '.' + halves[1] else ''
    pattern = /(\d+)(\d{3})/
    while pattern.test integer
      integer = integer.replace pattern, '$1' + ',' + '$2'
    integer + decimal

}
