require 'minitest/autorun'
require_relative '../../lib/options_parser'

class OptionsParserTest < Minitest::Test
  def test_smart_output_default_explicit_output
    assert_equal(
      { output: Pathname.new('/tmp'), file: '/home/bob/mapping.csv' },
      smart_output_default({ file: '/home/bob/mapping.csv', output: '/tmp' })
    )
  end

  def test_smart_output_from_input_file
    assert_equal(
      { output: Pathname.new('/home/bob'), file: '/home/bob/mapping.csv' },
      smart_output_default({ file: '/home/bob/mapping.csv' })
    )
  end
end
