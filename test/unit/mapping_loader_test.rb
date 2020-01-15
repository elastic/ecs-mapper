require 'minitest/autorun'
require_relative '../../lib/mapping_loader'

class MappingLoaderTest < Minitest::Test
  def test_explicit_mapping_default_rename_action
    raw_mapping = {
      'copied_field' => {
        source_field: 'copied_field',
        destination_field: 'new.copied_field',
        rename: 'copy'
      },
      'default_field' => {
        source_field: 'default_field',
        destination_field: 'new.default_field'
      },
      'renamed_field' => {
        source_field: 'renamed_field',
        destination_field: 'new.renamed_field',
        rename: 'rename'
      },
    }
    options = { rename: 'copy' }
    mapping = make_mapping_explicit(raw_mapping, options)
    assert_equal('copy', mapping['default_field'][:rename])
    assert_equal('copy', mapping['copied_field'][:rename])
    assert_equal('rename', mapping['renamed_field'][:rename])
  end

  def test_csv_to_mapping_cleans_up_spaces_ignores_unknown_keys
    # Note: an instance of CSV behaves a lot like an array of hashes
    csv = [{ 'source_field' => ' my_field ',
             'destination_field' => "another_field\t",
             'rename' => ' copy',
    }]
    expected_mapping = {
      'my_field' => {
        source_field: 'my_field',
        destination_field: 'another_field',
        rename: 'copy',
        format_action: nil,
      }
    }
    assert_equal(expected_mapping, csv_to_mapping(csv))
  end

  def test_validate!
    assert_raises(RuntimeError) do
      validate_mapping!({ 'foo' => {:format_action => 'foo'}})
    end

    # If no errors, this is good (no need for assertion)
    validate_mapping!({ 'foo' => {:format_action => 'to_array'}})
  end

  def test_mapping_loader_skips_missing_source_field
    csv = [
      # skipped
      { 'source_field' => nil,           'destination_field' => nil },
      { 'source_field' => nil,           'destination_field' => 'fieldname' },
      { 'source_field' => ' ',           'destination_field' => '  ' },
      { 'source_field' => "\t",           'destination_field' => 'fieldname' },
      # Not skipped
      { 'source_field' => 'correct_fieldname',  'destination_field' => nil },
      { 'source_field' => 'original_fieldname', 'destination_field' => 'new_fieldname' },
    ]
    expected_mapping = {
      'correct_fieldname' => {
        source_field: 'correct_fieldname',
        destination_field: nil,
        rename: nil,
        format_action: nil,
      },
      'original_fieldname' => {
        source_field: 'original_fieldname',
        destination_field: 'new_fieldname',
        rename: nil,
        format_action: nil,
      }
    }
    assert_equal(expected_mapping, csv_to_mapping(csv))
  end
end
