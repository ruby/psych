require 'minitest/autorun'
require 'psych'

class TestScalarScanner < MiniTest::Unit::TestCase
  def test_scan_time
    [ '2001-12-15T02:59:43.1Z',
      '2001-12-14t21:59:43.10-05:00',
      '2001-12-14 21:59:43.10 -5',
      '2001-12-15 2:59:43.10',
    ].each do |time|
      ss = Psych::ScalarScanner.new time
      assert_instance_of Time, ss.tokenize
    end
  end

  def test_scan_date
    date = '1980-12-16'
    ss = Psych::ScalarScanner.new date
    token = ss.tokenize
    assert_equal 1980, token.year
    assert_equal 12, token.month
    assert_equal 16, token.day
  end

  def test_scan_inf
    ss = Psych::ScalarScanner.new('.inf')
    assert_equal 1 / 0.0, ss.tokenize
  end

  def test_scan_minus_inf
    ss = Psych::ScalarScanner.new('-.inf')
    assert_equal -1 / 0.0, ss.tokenize
  end

  def test_scan_nan
    ss = Psych::ScalarScanner.new('.nan')
    assert ss.tokenize.nan?
  end

  def test_scan_null
    ss = Psych::ScalarScanner.new('null')
    assert_equal nil, ss.tokenize

    ss = Psych::ScalarScanner.new('~')
    assert_equal nil, ss.tokenize

    ss = Psych::ScalarScanner.new('')
    assert_equal nil, ss.tokenize
  end

  def test_scan_symbol
    ss = Psych::ScalarScanner.new(':foo')
    assert_equal :foo, ss.tokenize
  end

  def test_scan_sexagesimal_float
    ss = Psych::ScalarScanner.new('190:20:30.15')
    assert_equal 685230.15, ss.tokenize
  end

  def test_scan_sexagesimal_int
    ss = Psych::ScalarScanner.new('190:20:30')
    assert_equal 685230, ss.tokenize
  end

  def test_scan_float
    ss = Psych::ScalarScanner.new('1.2')
    assert_equal 1.2, ss.tokenize
  end

  def test_scan_true
    ss = Psych::ScalarScanner.new('true')
    assert_equal true, ss.tokenize
  end
end
