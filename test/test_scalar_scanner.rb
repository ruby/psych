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
      assert_equal :TIME, ss.tokenize.first
    end
  end

  def test_scan_date
    date = '1980-12-16'
    ss = Psych::ScalarScanner.new date
    type, token = ss.tokenize
    assert_equal :DATE, type
    assert_equal 1980, token.year
    assert_equal 12, token.month
    assert_equal 16, token.day
  end

  def test_scan_inf
    ss = Psych::ScalarScanner.new('.inf')
    assert_equal [:POSITIVE_INFINITY, 1 / 0.0], ss.tokenize
  end

  def test_scan_minus_inf
    ss = Psych::ScalarScanner.new('-.inf')
    assert_equal [:NEGATIVE_INFINITY, -1 / 0.0], ss.tokenize
  end

  def test_scan_nan
    ss = Psych::ScalarScanner.new('.nan')
    assert_equal :NAN, ss.tokenize.first
    assert ss.tokenize.last.nan?
  end

  def test_scan_null
    ss = Psych::ScalarScanner.new('null')
    assert_equal [:NULL, nil], ss.tokenize

    ss = Psych::ScalarScanner.new('~')
    assert_equal [:NULL, nil], ss.tokenize

    ss = Psych::ScalarScanner.new('')
    assert_equal [:NULL, nil], ss.tokenize
  end

  def test_scan_symbol
    ss = Psych::ScalarScanner.new(':foo')
    assert_equal [:SYMBOL, :foo], ss.tokenize
  end

  def test_scan_sexagesimal_float
    ss = Psych::ScalarScanner.new('190:20:30.15')
    assert_equal [:FLOAT, 685230.15], ss.tokenize
  end

  def test_scan_sexagesimal_int
    ss = Psych::ScalarScanner.new('190:20:30')
    assert_equal [:INTEGER, 685230], ss.tokenize
  end

  def test_scan_float
    ss = Psych::ScalarScanner.new('1.2')
    assert_equal [:FLOAT, 1.2], ss.tokenize
  end

  def test_scan_true
    ss = Psych::ScalarScanner.new('true')
    assert_equal [:BOOLEAN, true], ss.tokenize
  end
end
