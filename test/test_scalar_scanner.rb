require 'minitest/autorun'
require 'psych'

class TestScalarScanner < MiniTest::Unit::TestCase
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
    ss = Psych::ScalarScanner.new('y')
    assert_equal [:BOOLEAN, true], ss.tokenize
  end
end
