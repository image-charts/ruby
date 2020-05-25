require 'image-charts'

chart_path = '/tmp/chart.png';

ImageCharts()
.cht('bvg') # vertical bar chart
.chs('300x300') # 300px x 300px
.chd('a:60,40') # 2 data points: 60 and 40
.to_file(chart_path)
