require 'minitest/autorun'
require_relative '../../lib/elasticsearch_pipeline_generator'

class OptionsParserTest < Minitest::Test
  def test_copy_processor
    mapping = { 'old_field+new_field' => {
      source_field: 'old_field', destination_field: 'new_field', copy_action: 'copy'
    } }
    pl = generate_elasticsearch_pipeline(mapping)
    processor = pl.first
    assert_equal(
      { set: { field: 'new_field', value: '{{old_field}}', if: 'ctx.old_field != null' } },
      processor
    )
  end

  def test_rename_processor
    mapping = { 'old_field+new_field' => {
      source_field: 'old_field', destination_field: 'new_field', copy_action: 'rename'
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
      'field1+field1' => { source_field: 'field1', destination_field: 'field1', copy_action: 'copy' },
      'field2+' => { source_field: 'field2', destination_field: nil, copy_action: 'copy' },
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

  def test_duplicate_source_fields_same_destination
    mapping = {
      'field1+field3' => { source_field: 'field1', destination_field: 'field3', copy_action: 'copy' },
      'field2+field3' => { source_field: 'field2', destination_field: 'field3', copy_action: 'copy' },
      'field4+field5' => { source_field: 'field4', destination_field: 'field5', copy_action: 'copy' },
      'field4+field6' => { source_field: 'field4', destination_field: 'field6', copy_action: 'copy' },
    } 

    pl = generate_elasticsearch_pipeline(mapping)

    assert_equal(4, pl.length, "Expected 4 processors")   
    assert_equal(
      {:set=>{:field=>"field3", :value=>"{{field1}}", :if=>"ctx.field1 != null"}},
      pl[0]
    )
    assert_equal(
      {:set=>{:field=>"field3", :value=>"{{field2}}", :if=>"ctx.field2 != null"}},
      pl[1]
    ) 
    assert_equal(
      {:set=>{:field=>"field5", :value=>"{{field4}}", :if=>"ctx.field4 != null"}},
      pl[2]
    )
    assert_equal(
      {:set=>{:field=>"field6", :value=>"{{field4}}", :if=>"ctx.field4 != null"}},
      pl[3]
    )         
  end

  def test_dates
    mapping = {
      'field1+@timestamp' => 
        { source_field: 'field1', 
          destination_field: '@timestamp',
          format_action: 'to_timestamp_unix_ms' },
      'field2+@timestamp' =>
        { source_field: 'field2',
          destination_field: '@timestamp',
          format_action: 'to_timestamp_unix' },
    }

    pl = generate_elasticsearch_pipeline(mapping)

    assert_equal(
      { "date" => {
        :field => "field1", 
        :target_field => "@timestamp", 
        :formats => ["UNIX_MS"], 
        :timezone => "UTC", 
        :ignore_failure => true}},
      pl[0]
    )

    assert_equal(
      { "date" => {
        :field => "field2", 
        :target_field => "@timestamp", 
        :formats => ["UNIX"], 
        :timezone => "UTC", 
        :ignore_failure => true}},
      pl[1]
    )
  end
end
