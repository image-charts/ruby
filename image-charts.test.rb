# Run tests from the repository root directory:
# $ bundle install && bundle exec ruby test/platform.ruby.test.rb
require 'minitest/autorun'

require_relative './image-charts.rb'


class TestImageCharts < Minitest::Test

def test_can_instance_without_new
    inst = ImageCharts()
    assert inst.instance_of? ImageCharts
  end

  def test_to_url_works
    ImageCharts().cht('p').chd('t:1,2,3')
    assert_equal ImageCharts().cht('p').chd('t:1,2,3').to_url(), 'https://image-charts.com:443/chart?cht=p&chd=t%3A1%2C2%2C3'
  end


  def test_exposes_parameters_and_use_them
    chart = ImageCharts()
    query = ''

    chart.public_methods(false)
        .find_all {|method| method.to_s.start_with?('c') || method.to_s.start_with?('ic') }
        .each do |method_name|
            chart = chart.public_send(method_name, 'plop')
            query += "&#{method_name}=plop"
        end

    assert_equal chart.to_url, "https://image-charts.com:443/chart?#{query[1..-1]}"
  end


  def test_adds_a_signature_when_icac_and_secrets_are_defined
    assert_equal ImageCharts(secret: "plop").cht('p').chd('t:1,2,3').chs('100x100').icac('test_fixture').to_url, 'https://image-charts.com:443/chart?cht=p&chd=t%3A1%2C2%2C3&chs=100x100&icac=test_fixture&ichm=71bd93758b49ed28fdabd23a0ff366fe7bf877296ea888b9aaf4ede7978bdc8d'
  end

  def test_rejects_if_a_chs_is_not_defined
    err = assert_raises ImageChartsError do
      ImageCharts().cht('p').chd('t:1,2,3').to_blob
    end
    assert_equal err.message, '"chs" is required'
  end


  def test_rejects_if_a_icac_is_defined_without_ichm
    err = assert_raises ImageChartsError do
      ImageCharts().cht('p').chd('t:1,2,3').chs('100x100').icac('test_fixture').to_blob
    end
    assert_equal 'IC_MISSING_ENT_PARAMETER', err.validation_code
  end

  def test_rejects_if_timeout_is_reached
    err = assert_raises Net::OpenTimeout do
      ImageCharts(timeout: 0.01).cht('p').chd('t:1,2,3').chs('100x100').chan('1200').to_blob
    end
    assert_equal 'Failed to open TCP connection to image-charts.com:443 (execution expired)', err.message
  end

  def test_to_blob_works
    size = ImageCharts().cht('p').chd('t:1,2,3').chs('2x2').to_blob.length
    assert_equal true, size > 60, '#{size} > 60'
  end

  def test_forwards_package_name_version_as_user_agent
    chart = ImageCharts().cht('p').chd('t:1,2,3').chs('10x10')
    chart.to_blob
    assert_equal 'ruby-image-charts/latest', chart.request_headers['user-agent']
  end

  def test_forwards_package_name_version_icac_as_user_agent
    chart = ImageCharts(secret: 'plop').cht('p').chd('t:1,2,3').chs('10x10').icac('MY_ACCOUNT_ID')

    begin
      chart.to_blob
    rescue
      # ignored
    end

    assert_equal 'ruby-image-charts/latest (MY_ACCOUNT_ID)', chart.request_headers['user-agent']
  end

  def test_throw_error_if_account_not_found
    err = assert_raises ImageChartsError do
      ImageCharts(secret: 'plop').cht('p').chd('t:1,2,3').chs('10x10').icac('MY_ACCOUNT_ID').to_blob
    end
    assert_equal 'IC_ACCOUNT_ID_NOT_FOUND', err.validation_code
  end

  def test_rejects_if_there_was_an_error
    err = assert_raises ImageChartsError do
      ImageCharts().cht('p').chd('t:1,2,3').to_data_uri
    end
    assert_equal '"chs" is required', err.message

  end

  def test_to_data_uri_works
    assert_equal 'data:image/png;base64,iVBORw0K', ImageCharts().cht('p').chd('t:1,2,3').chs('2x2').to_data_uri()[0..29]
  end

  def test_to_file_throw_exception_if_bad_path
    err = assert_raises Errno::ENOENT do
      ImageCharts().cht('p').chd('t:1,2,3').chs('2x2').to_file '/tmp_oiqsjosijd/chart.png'
    end
    assert_equal 'No such file or directory @ rb_sysopen - /tmp_oiqsjosijd/chart.png', err.message
  end

  def test_to_file_works
    ret = ImageCharts().cht('p').chd('t:1,2,3').chs('2x2').to_file('/tmp/chart-rb.png')
    assert_nil ret
    assert File.file?('/tmp/chart-rb.png')
  end

  def test_support_gif
    assert_equal 'data:image/gif;base64,R0lGODlh', ImageCharts().cht('p').chd('t:1,2,3').chan('100').chs('2x2').to_data_uri()[0..29]
  end

  def test_expose_the_protocol
    assert_equal ImageCharts()._protocol, 'https'
  end

  def test_let_protocol_to_be_user_defined
    assert_equal ImageCharts(protocol: 'http')._protocol, 'http'
  end

  def test_expose_the_host
    assert_equal ImageCharts()._host, 'image-charts.com'
  end

  def test_let_host_to_be_user_defined
    assert_equal ImageCharts(host: 'on-premise-image-charts.com')._host, 'on-premise-image-charts.com'
  end

  def test_expose_the_pathname
    assert_equal ImageCharts()._pathname, '/chart'
  end

  def test_expose_the_port
    assert_equal ImageCharts()._port, 443
  end

  def test_let_port_to_be_user_defined
    assert_equal ImageCharts(port: 8080)._port, 8080
  end

  def test_expose_the_query
    assert_equal ImageCharts()._query, {}
  end

  def test_expose_the_query_user_defined
    assert_equal ImageCharts().cht('p').chd('t:1,2,3').icac('plop')._query, {"cht" => 'p', "chd" => 't:1,2,3', "icac" => 'plop'}
  end
end
