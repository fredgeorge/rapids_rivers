require 'test_helper'

# Ensures PacketProblems can be indentified and rendered correctly
class PacketProblemsTest < MiniTest::Test

  JSON_STRING = {"key1" => "value1"}.to_json

  def setup
    @problems = PacketProblems.new(JSON_STRING)
  end

  def test_no_problems_found_default
    refute @problems.errors?
  end

  def test_errors_detected
    @problems.error('Simple error')
    assert @problems.errors?
    assert_match 'Simple error', @problems.to_s
  end

  def test_severe_errors_detected
    @problems.severe_error('Severe error')
    assert @problems.errors?
    assert_match 'Severe error', @problems.to_s
  end

  def test_warnings_detected
    @problems.warning('Warning')
    refute @problems.errors?
    assert_match 'Warning', @problems.to_s
  end

  def test_information_detected
    @problems.information('Informational message')
    refute @problems.errors?
    assert_match 'Informational message', @problems.to_s
  end

end
