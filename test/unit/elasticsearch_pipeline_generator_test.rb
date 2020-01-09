require 'minitest/autorun'
require_relative '../../lib/elasticsearch_pipeline_generator'

class OptionsParserTest < Minitest::Test
  def test_copy_processor
    mapping = { 'old_field' => {
      source_field: 'old_field', destination_field: 'new_field', rename: 'copy'
    } }
    pl = generate_elasticsearch_pipeline(mapping)
    processor = pl.first
    assert_equal(
      { set: { field: 'new_field', value: '{{old_field}}', if: 'ctx.old_field != null' } },
      processor
    )
  end

  def test_rename_processor
    mapping = { 'old_field' => {
      source_field: 'old_field', destination_field: 'new_field', rename: 'rename'
    } }
    pl = generate_elasticsearch_pipeline(mapping)
    processor = pl.first
    assert_equal(
      { rename: { field: 'old_field', target_field: 'new_field', ignore_missing: true } },
      processor
    )
  end

  def test_non_renamed_elasticsearch
    mapping = {
      'field1' => { source_field: 'field1', destination_field: 'field1', rename: 'copy' },
      'field2' => { source_field: 'field2', destination_field: nil, rename: 'copy' },
    }
    pl = generate_elasticsearch_pipeline(mapping)
    assert_equal([], pl, "No rename processor should be added when there's no rename to perform")
  end

  def test_field_presence_predicate
    assert_equal('ctx.level != null',
                 field_presence_predicate('level'))
    assert_equal('ctx.suricata?.eve?.http?.hostname != null',
                 field_presence_predicate('suricata.eve.http.hostname'))

    assert_equal("ctx.containsKey('@timestamp')",
                 field_presence_predicate('@timestamp'))
  end
end
