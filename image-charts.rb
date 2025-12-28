# encoding: utf-8
# warn_indent: true

require 'uri'
require 'openssl'
require 'net/http'
require 'json'
require 'rubygems'
require 'base64'

#
# Image-Charts API URL builder
#
class ImageCharts
  attr_reader :request_headers, :_protocol, :_host, :_port, :_pathname, :_timeout, :_query

  def initialize(secret: nil, protocol: 'https', host: 'image-charts.com', port: 443, timeout: 5000, user_agent: nil, previous: nil)
    @_protocol = protocol
    @_host = host
    @_port = port
    @_pathname = '/chart'
    @_timeout = timeout
    @_query = if previous then previous else Hash.new(0) end
    @_secret = secret
    @_user_agent = user_agent
  end

  #
  # Get the full Image-Charts API url (signed and encoded if necessary)
  # @return {string} full generated url
  #
  def to_url()
    search_params = URI.encode_www_form(@_query)

    if @_query.has_key?("icac") && @_secret && @_secret.length > 1
      signature = OpenSSL::HMAC.hexdigest('SHA256', @_secret, search_params)
      search_params += "&ichm=#{signature}"
    end

    "#{@_protocol}://#{@_host}:#{@_port}#{@_pathname}?#{search_params}"
  end

   #
   # Do a request to Image-Charts API with current configuration and yield a binary string
   # @return {String} raw image data, binary string
   #
   def to_blob()

     spec = Gem.loaded_specs["image-charts"]
     default_user_agent = "ruby-image-charts/" + (if spec then spec.version.to_s else 'latest' end) + (if @_query.has_key?('icac') then " (#{@_query['icac']})" else '' end)
     @request_headers = {"user-agent" => (@_user_agent || default_user_agent)}

     http = Net::HTTP.new(@_host, @_port)

     http.read_timeout= @_timeout
     http.open_timeout= @_timeout
     http.use_ssl = true
     http.verify_mode = OpenSSL::SSL::VERIFY_PEER
     res = http.request(Net::HTTP::Get.new(URI(to_url), @request_headers))

     if (200..300).cover? res.code.to_i
       return res.body
     end


     validation_message = res['x-ic-error-validation']
     validation_code = res['x-ic-error-code']

     message = if validation_message && validation_message.length > 0 then
        JSON.parse(validation_message).map {|x| x['message']}.join("\n")
     elsif validation_code && validation_code.length > 0 then
        validation_code
     else
        res.code.to_s
     end

     raise ImageChartsError.new(message, (validation_code || "HTTP_#{res.code}"), res.code)
   end

   #
   # Do a request to Image-Charts API with current configuration and writes the content inside a file
   # @return {Promise}
   #
   def to_file(file)
     data = to_blob()
     File.open(file, "wb") {
       |file| file.puts data
     }
   end

   #
   # Do a request to Image-Charts API with current configuration and yield a promise of a base64 encoded data URI
   # @return {Promise<String>} base64 data URI wrapped inside a promise
   #
   def to_data_uri()
     encoding = 'base64'
     mimetype = if @_query.has_key?('chan') then 'image/gif' else 'image/png' end
     return "data:#{mimetype};#{encoding},#{Base64.encode64(to_blob())}"
   end


  
    # bvg= grouped bar chart, bvs= stacked bar chart, lc=line chart, ls=sparklines, p=pie chart. gv=graph viz
	#         Three-dimensional pie chart (p3) will be rendered in 2D, concentric pie chart are not supported.
	#         [Optional, line charts only] You can add :nda after the chart type in line charts to hide the default axes.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-type/}
    # # @example
    # chart = ImageCharts().cht('bvg')
    # chart = ImageCharts().cht('p')
    # 
    # Chart type
    def cht(value)
      _clone 'cht', value
    end
  
    # chart data
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/data-format/}
    # # @example
    # chart = ImageCharts().chd('a:-100,200.5,75.55,110')
    # chart = ImageCharts().chd('t:10,20,30|15,25,35')
    # chart = ImageCharts().chd('s:BTb19_,Mn5tzb')
    # chart = ImageCharts().chd('e:BaPoqM2s,-A__RMD6')
    # 
    # chart data
    def chd(value)
      _clone 'chd', value
    end
  
    # You can configure some charts to scale automatically to fit their data with chds=a. The chart will be scaled so that the largest value is at the top of the chart and the smallest (or zero, if all values are greater than zero) will be at the bottom. Otherwise the &#34;&amp;lg;series_1_min&amp;gt;,&amp;lg;series_1_max&amp;gt;,...,&amp;lg;series_n_min&amp;gt;,&amp;lg;series_n_max&amp;gt;&#34; format set one or more minimum and maximum permitted values for each data series, separated by commas. You must supply both a max and a min. If you supply fewer pairs than there are data series, the last pair is applied to all remaining data series. Note that this does not change the axis range; to change the axis range, you must set the chxr parameter. Valid values range from (+/-)9.999e(+/-)199. You can specify values in either standard or E notation.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/data-format/#text-format-with-custom-scaling}
    # # @example
    # chart = ImageCharts().chds('-80,140')
    # 
    # data format with custom scaling
    def chds(value)
      _clone 'chds', value
    end
  
    # How to encode the data in the QR code. &#39;UTF-8&#39; is the default and only supported value. Contact our team if you wish to have support for Shift_JIS and/or ISO-8859-1.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/qr-codes/#data-encoding}
    # # @example
    # chart = ImageCharts().choe('UTF-8')
    # 
    # QRCode data encoding
    def choe(value)
      _clone 'choe', value
    end
  
    # QRCode error correction level and optional margin
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/qr-codes/#error-correction-level-and-margin}
    # # @example
    # chart = ImageCharts().chld('L|4')
    # chart = ImageCharts().chld('M|10')
    # chart = ImageCharts().chld('Q|5')
    # chart = ImageCharts().chld('H|18')
    # @default 'L|4'
    # QRCode error correction level and optional margin
    def chld(value)
      _clone 'chld', value
    end
  
    # You can specify the range of values that appear on each axis independently, using the chxr parameter. Note that this does not change the scale of the chart elements (use chds for that), only the scale of the axis labels.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-axis/#axis-range}
    # # @example
    # chart = ImageCharts().chxr('0,0,200')
    # chart = ImageCharts().chxr('0,10,50,5')
    # chart = ImageCharts().chxr('0,0,500|1,0,200')
    # 
    # Axis data-range
    def chxr(value)
      _clone 'chxr', value
    end
  
    # Some clients like Flowdock/Facebook messenger and so on, needs an URL to ends with a valid image extension file to display the image, use this parameter at the end your URL to support them. Valid values are &#34;.png&#34;, &#34;.svg&#34; and &#34;.gif&#34;.
	#           Only QRCodes and GraphViz support svg output.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/output-format/}
    # # @example
    # chart = ImageCharts().chof('.png')
    # chart = ImageCharts().chof('.svg')
    # chart = ImageCharts().chof('.gif')
    # @default '.png'
    # Image output format
    def chof(value)
      _clone 'chof', value
    end
  
    # Maximum chart size for all charts except maps is 998,001 pixels total (Google Image Charts was limited to 300,000), and maximum width or length is 999 pixels.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-size/}
    # # @example
    # chart = ImageCharts().chs('400x400')
    # 
    # Chart size (&lt;width&gt;x&lt;height&gt;)
    def chs(value)
      _clone 'chs', value
    end
  
    # Format: &amp;lt;data_series_1_label&amp;gt;|...|&amp;lt;data_series_n_label&amp;gt;. The text for the legend entries. Each label applies to the corresponding series in the chd array. Use a + mark for a space. If you do not specify this parameter, the chart will not get a legend. There is no way to specify a line break in a label. The legend will typically expand to hold your legend text, and the chart area will shrink to accommodate the legend.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/legend-text-and-style/}
    # # @example
    # chart = ImageCharts().chdl('NASDAQ|FTSE100|DOW')
    # 
    # Text for each series, to display in the legend
    def chdl(value)
      _clone 'chdl', value
    end
  
    # Specifies the color and font size of the legend text. &lt;color&gt;,&lt;size&gt;
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/legend-text-and-style/}
    # # @example
    # chart = ImageCharts().chdls('9e9e9e,17')
    # @default '000000'
    # Chart legend text and style
    def chdls(value)
      _clone 'chdls', value
    end
  
    # Solid or dotted grid lines
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/grid-lines/}
    # # @example
    # chart = ImageCharts().chg('1,1')
    # chart = ImageCharts().chg('0,1,1,5')
    # chart = ImageCharts().chg('1,1,FF00FF')
    # chart = ImageCharts().chg('1,1,1,1,CECECE')
    # 
    # Solid or dotted grid lines
    def chg(value)
      _clone 'chg', value
    end
  
    # You can specify the colors of a specific series using the chco parameter.
	#       Format should be &amp;lt;series_2&amp;gt;,...,&amp;lt;series_m&amp;gt;, with each color in RRGGBB format hexadecimal number.
	#       The exact syntax and meaning can vary by chart type; see your specific chart type for details.
	#       Each entry in this string is an RRGGBB[AA] format hexadecimal number.
	#       If there are more series or elements in the chart than colors specified in your string, the API typically cycles through element colors from the start of that series (for elements) or for series colors from the start of the series list.
	#       Again, see individual chart documentation for details.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/bar-charts/#examples}
    # # @example
    # chart = ImageCharts().chco('FFC48C')
    # chart = ImageCharts().chco('FF0000,00FF00,0000FF')
    # @default 'F56991,FF9F80,FFC48C,D1F2A5,EFFAB4'
    # series colors
    def chco(value)
      _clone 'chco', value
    end
  
    # chart title
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-title/}
    # # @example
    # chart = ImageCharts().chtt('My beautiful chart')
    # 
    # chart title
    def chtt(value)
      _clone 'chtt', value
    end
  
    # Format should be &#34;&lt;color&gt;,&lt;font_size&gt;[,&lt;opt_alignment&gt;,&lt;opt_font_family&gt;,&lt;opt_font_style&gt;]&#34;, opt_alignement is not supported
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-title/}
    # # @example
    # chart = ImageCharts().chts('00FF00,17')
    # 
    # chart title colors and font size
    def chts(value)
      _clone 'chts', value
    end
  
    # Specify which axes you want (from: &#34;x&#34;, &#34;y&#34;, &#34;t&#34; and &#34;r&#34;). You can use several of them, separated by a coma; for example: &#34;x,x,y,r&#34;. Order is important.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-axis/#visible-axes}
    # # @example
    # chart = ImageCharts().chxt('y')
    # chart = ImageCharts().chxt('x,y')
    # chart = ImageCharts().chxt('x,x,y')
    # chart = ImageCharts().chxt('x,y,t,r,t')
    # 
    # Display values on your axis lines or change which axes are shown
    def chxt(value)
      _clone 'chxt', value
    end
  
    # Specify one parameter set for each axis that you want to label. Format &#34;&lt;axis_index&gt;:|&lt;label_1&gt;|...|&lt;label_n&gt;|...|&lt;axis_index&gt;:|&lt;label_1&gt;|...|&lt;label_n&gt;&#34;. Separate multiple sets of labels using the pipe character ( | ).
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-axis/#custom-axis-labels}
    # # @example
    # chart = ImageCharts().chxl('0:|Jan|July|Jan')
    # chart = ImageCharts().chxl('0:|Jan|July|Jan|1|10|20|30')
    # 
    # Custom string axis labels on any axis
    def chxl(value)
      _clone 'chxl', value
    end
  
    # You can specify the range of values that appear on each axis independently, using the chxr parameter. Note that this does not change the scale of the chart elements (use chds for that), only the scale of the axis labels.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-axis/#axis-label-styles}
    # # @example
    # chart = ImageCharts().chxs('1,0000DD')
    # chart = ImageCharts().chxs('1N*cUSD*Mil,FF0000')
    # chart = ImageCharts().chxs('1N*cEUR*,FF0000')
    # chart = ImageCharts().chxs('2,0000DD,13,0,t')
    # chart = ImageCharts().chxs('0N*p*per-month,0000FF')
    # chart = ImageCharts().chxs('0N*e*,000000|1N*cUSD*Mil,FF0000|2N*2sz*,0000FF')
    # 
    # Font size, color for axis labels, both custom labels and default label values
    def chxs(value)
      _clone 'chxs', value
    end
  
    # 
	# format should be either:
	#   - line fills (fill the area below a data line with a solid color): chm=&lt;b_or_B&gt;,&lt;color&gt;,&lt;start_line_index&gt;,&lt;end_line_index&gt;,&lt;0&gt; |...| &lt;b_or_B&gt;,&lt;color&gt;,&lt;start_line_index&gt;,&lt;end_line_index&gt;,&lt;0&gt;
	#   - line marker (add a line that traces data in your chart): chm=D,&lt;color&gt;,&lt;series_index&gt;,&lt;which_points&gt;,&lt;width&gt;,&lt;opt_z_order&gt;
	#   - Text and Data Value Markers: chm=N&lt;formatting_string&gt;,&lt;color&gt;,&lt;series_index&gt;,&lt;which_points&gt;,&lt;width&gt;,&lt;opt_z_order&gt;,&lt;font_family&gt;,&lt;font_style&gt;
	#     
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/compound-charts/}
    # # @example

    # 
    # compound charts and line fills
    def chm(value)
      _clone 'chm', value
    end
  
    # line thickness and solid/dashed style
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/line-charts/#line-styles}
    # # @example
    # chart = ImageCharts().chls('10')
    # chart = ImageCharts().chls('3,6,3|5')
    # 
    # line thickness and solid/dashed style
    def chls(value)
      _clone 'chls', value
    end
  
    # If specified it will override &#34;chdl&#34; values
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-label/}
    # # @example
    # chart = ImageCharts().chl('label1|label2')
    # chart = ImageCharts().chl('multi# line# label1|label2')
    # 
    # bar, pie slice, doughnut slice and polar slice chart labels
    def chl(value)
      _clone 'chl', value
    end
  
    # Position and style of labels on data
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-label/#positionning-and-formatting}
    # # @example
    # chart = ImageCharts().chlps('align,top|offset,10|color,FF00FF')
    # chart = ImageCharts().chlps('align,top|offset,10|color,FF00FF')
    # 
    # Position and style of labels on data
    def chlps(value)
      _clone 'chlps', value
    end
  
    # chart margins
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-margin/}
    # # @example
    # chart = ImageCharts().chma('30,30,30,30')
    # chart = ImageCharts().chma('40,20')
    # 
    # chart margins
    def chma(value)
      _clone 'chma', value
    end
  
    # Position of the legend and order of the legend entries
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/legend-text-and-style/}
    # # @example

    # @default 'r'
    # Position of the legend and order of the legend entries
    def chdlp(value)
      _clone 'chdlp', value
    end
  
    # Background Fills
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/background-fill/}
    # # @example
    # chart = ImageCharts().chf('b0,lg,0,f44336,0.3,03a9f4,0.8')
    # @default 'bg,s,FFFFFF'
    # Background Fills
    def chf(value)
      _clone 'chf', value
    end
  
    # Bar corner radius. Display bars with rounded corner.
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/bar-charts/#rounded-bar}
    # # @example
    # chart = ImageCharts().chbr('5')
    # chart = ImageCharts().chbr('10')
    # 
    # Bar corner radius. Display bars with rounded corner.
    def chbr(value)
      _clone 'chbr', value
    end
  
    # gif configuration
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/animation/}
    # # @example
    # chart = ImageCharts().chan('1200')
    # chart = ImageCharts().chan('1300|easeInOutSine')
    # 
    # gif configuration
    def chan(value)
      _clone 'chan', value
    end
  
    # doughnut chart inside label
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/pie-charts/#inside-label}
    # # @example
    # chart = ImageCharts().chli('95K€')
    # chart = ImageCharts().chli('45%')
    # 
    # doughnut chart inside label
    def chli(value)
      _clone 'chli', value
    end
  
    # image-charts enterprise `account_id`
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/enterprise/}
    # # @example
    # chart = ImageCharts().icac('accountId')
    # 
    # image-charts enterprise `account_id`
    def icac(value)
      _clone 'icac', value
    end
  
    # HMAC-SHA256 signature required to activate paid features
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/enterprise/}
    # # @example
    # chart = ImageCharts().ichm('0785cf22a0381c2e0239e27c126de4181f501d117c2c81745611e9db928b0376')
    # 
    # HMAC-SHA256 signature required to activate paid features
    def ichm(value)
      _clone 'ichm', value
    end
  
    # How to use icff to define font family as Google Font : https://developers.google.com/fonts/docs/css2
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-font/}
    # # @example
    # chart = ImageCharts().icff('Abel')
    # chart = ImageCharts().icff('Akronim')
    # chart = ImageCharts().icff('Alfa Slab One')
    # 
    # Default font family for all text from Google Fonts. Use same syntax as Google Font CSS API
    def icff(value)
      _clone 'icff', value
    end
  
    # Default font style for all text
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/chart-font/}
    # # @example
    # chart = ImageCharts().icfs('normal')
    # chart = ImageCharts().icfs('italic')
    # 
    # Default font style for all text
    def icfs(value)
      _clone 'icfs', value
    end
  
    # localization (ISO 639-1)
    #
    # [Reference documentation]{@link }
    # # @example
    # chart = ImageCharts().iclocale('en')
    # 
    # localization (ISO 639-1)
    def iclocale(value)
      _clone 'iclocale', value
    end
  
    # Retina is a marketing term coined by Apple that refers to devices and monitors that have a resolution and pixel density so high — roughly 300 or more pixels per inch – that a person is unable to discern the individual pixels at a normal viewing distance.
	#           In order to generate beautiful charts for these Retina displays, Image-Charts supports a retina mode that can be activated through the icretina=1 parameter
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/reference/retina/}
    # # @example
    # chart = ImageCharts().icretina('1')
    # 
    # retina mode
    def icretina(value)
      _clone 'icretina', value
    end
  
    # Background color for QR Codes
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/qr-codes/#background-color}
    # # @example
    # chart = ImageCharts().icqrb('FFFFFF')
    # @default 'FFFFFF'
    # Background color for QR Codes
    def icqrb(value)
      _clone 'icqrb', value
    end
  
    # Foreground color for QR Codes
    #
    # [Reference documentation]{@link https://documentation.image-charts.com/qr-codes/#foreground-color}
    # # @example
    # chart = ImageCharts().icqrf('000000')
    # @default '000000'
    # Foreground color for QR Codes
    def icqrf(value)
      _clone 'icqrf', value
    end
  

  private

  def _clone(param, value)
    add = Hash[]
    add.merge!(@_query)
    add[param] = value
    ImageCharts(
      protocol: @_protocol,
      host: @_host,
      port: @_port,
      timeout: @_timeout,
      secret: @_secret,
      user_agent: @_user_agent,
      previous: add)
  end

end

class ImageChartsError < StandardError
  attr_reader :validation_code, :status_code
  def initialize(message, validation_code, status_code)
    @exception_type = "custom"
    @validation_code = validation_code
    @status_code = status_code
    super(message)
  end
end


def ImageCharts(*args)
  if RUBY_VERSION.to_i >= 3
    args.any? ? ImageCharts.new(**args[0]) : ImageCharts.new(*args)
  else
    ImageCharts.new(*args)
  end
end
