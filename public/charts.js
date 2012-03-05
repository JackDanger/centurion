var Chart;

Chart = {
  commits: function(project, commits) {
    commits = _.map(commits.models, function(commit) {
      return commit.attributes;
    });
    commits = _.sortBy(commits, function(commit) {
      return commit.date;
    });
    Chart.flog(project, commits);
    return Chart.flogAverage(project, commits);
  },
  flog: function(project, commits) {
    var options;
    options = {
      legend: {
        enabled: false
      },
      chart: {
        defaultSeriesType: 'spline',
        renderTo: 'flogChart'
      },
      title: {
        text: 'total complexity of ' + project.get('name')
      },
      subtitle: {
        text: commits.length + ' commits'
      },
      xAxis: {
        type: '',
        dateTimeLabelFormats: {
          month: function(a, b) {
            console.log(a, b);
            return '%e. %b';
          },
          year: '%b'
        }
      },
      yAxis: {
        title: {
          text: 'Total complexity'
        },
        min: 0
      },
      tooltip: {
        formatter: function() {
          var commit;
          commit = this.point.config[2];
          return '<b>' + this.series.name + '</b><br/>' + Highcharts.dateFormat('%e. %b', new Date(1000 * commit.date)) + ': ' + Chart.withCommas(parseInt(this.y)) + '<br>' + commit.comment.replace("\n", "<br/>");
        }
      },
      series: [
        {
          name: '<b>Flog</b> complexity total',
          color: '#F24',
          data: _.map(commits, function(commit, idx) {
            return [commit.date, commit.flog, commit];
          })
        }
      ]
    };
    return window.chart = new Highcharts.Chart(options);
  },
  flogAverage: function(project, commits) {
    var options;
    options = {
      legend: {
        enabled: false
      },
      chart: {
        type: 'spline',
        renderTo: 'flogAverageChart'
      },
      title: {
        text: 'average method complexity of ' + project.get('name')
      },
      subtitle: {
        text: commits.length + ' commits'
      },
      yAxis: {
        title: {
          text: 'Average method complexity'
        },
        min: 0
      },
      xAxis: {
        type: 'datetime',
        dateTimeLabelFormats: {
          month: '%e. %b',
          year: '%b'
        }
      },
      tooltip: {
        formatter: function() {
          var commit;
          commit = this.point.config[2];
          return '<b>' + this.series.name + '</b><br/>' + Highcharts.dateFormat('%e. %b', new Date(1000 * commit.date)) + ': ' + Chart.withCommas(parseInt(this.y)) + '<br>' + commit.comment.replace("\n", "<br/>");
        }
      },
      commits: commits,
      series: [
        {
          name: '<b>Flog</b> method complexity average',
          color: '#454',
          data: _.map(commits, function(commit) {
            return [commit.date, commit.flogAverage, commit];
          })
        }
      ]
    };
    return new Highcharts.Chart(options);
  },
  withCommas: function(number) {
    var decimal, halves, integer, pattern;
    halves = number.toString().split('.');
    integer = halves[0];
    decimal = halves[1] ? '.' + halves[1] : '';
    pattern = /(\d+)(\d{3})/;
    while (pattern.test(integer)) {
      integer = integer.replace(pattern, '$1' + ',' + '$2');
    }
    return integer + decimal;
  }
};
