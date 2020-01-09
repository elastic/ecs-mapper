require 'minitest/autorun'
require_relative '../../lib/helpers'

class HelpersTest < Minitest::Test
  def test_same_field_name
    assert same_field_name?({source_field: 'foo', destination_field: nil})
    assert same_field_name?({source_field: 'foo', destination_field: 'foo'})

    assert_equal false, same_field_name?({source_field: 'foo', destination_field: 'bar'})
  end
end
