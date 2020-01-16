require 'minitest/autorun'
require_relative '../../lib/options_parser'

class OptionsParserTest < Minitest::Test
  def test_smart_output_from_input_file
    assert_equal(
      { file: '/home/bob/mapping.csv', output: Pathname.new('/home/bob') },
      smart_output_default({ file: '/home/bob/mapping.csv' })
    )
  end

  def test_smart_output_default_explicit_output
    assert_equal(
      { file: 'mapping.csv', output: Pathname.new('/tmp') },
      smart_output_default({ file: 'mapping.csv', output: '/tmp' })
    )
  end

  def test_output_dir_is_expanded
    current_user_home = Pathname.new('~').expand_path
    assert_equal(
      { file: 'mapping.csv', output: current_user_home },
      smart_output_default({ file: 'mapping.csv', output: '~' })
    )
  end
end
