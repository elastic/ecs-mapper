require 'minitest/autorun'
require_relative '../../lib/logstash_pipeline_generator'

class LogstashPipelineGeneratorTest < Minitest::Test
  def test_logstash_pipeline
    mapping = {
      'old1' => { source_field: 'old1', destination_field: 'new1', copy_action: 'copy' },
      'old2' => { source_field: 'old2', destination_field: 'new2', copy_action: 'rename' },
      'old3' => { source_field: 'old3', destination_field: 'new3', copy_action: 'copy' },
    }
    mutations, _, _ = generate_logstash_pipeline(mapping)
    old1_processor = mutations[0]
    old2_processor = mutations[1]
    old3_processor = mutations[2]
    assert_equal( { 'copy'   => { '[old1]' => '[new1]' } }, old1_processor)
    assert_equal( { 'rename' => { '[old2]' => '[new2]' } }, old2_processor)
    assert_equal( { 'copy'   => { '[old3]' => '[new3]' } }, old3_processor)
  end

  def test_non_renamed_ls
    mapping = {
      'field1' => { source_field: 'field1', destination_field: 'field1', copy_action: 'copy' },
      'field2' => { source_field: 'field2', destination_field: nil, copy_action: 'copy' },
    }
    mutations, _, _ = generate_logstash_pipeline(mapping)
    assert_equal([], mutations, "No rename processor should be added when there's no rename to perform")
  end

  def test_render_ls_field_name
    assert_equal("[field]",       lsf("field"))
    assert_equal("[@field]",      lsf("@field"))
    assert_equal("[log][level]",  lsf("log.level"))
  end

  def test_render_mutate_line_simple_hash
    assert_equal(
      "copy => { '[src_field]' => '[dest_field]' }",
      render_mutate_line('copy' => {'[src_field]' => '[dest_field]'})
    )
    assert_equal(
      "convert => { '[event][duration]' => 'float' }",
      render_mutate_line('convert' => {'[event][duration]' => 'float'})
    )
  end

  def test_render_mutate_line_array
    assert_equal(
      "uppercase => [ '[log][level]' ]",
      render_mutate_line('uppercase' => ['[log][level]'])
    )
  end

  def test_duplicate_source_fields_same_destination
    mapping = {
      'field1+field3' => { source_field: 'field1', destination_field: 'field3', copy_action: 'copy' },
      'field2+field3' => { source_field: 'field2', destination_field: 'field3', copy_action: 'copy' },
      'field4+field5' => { source_field: 'field4', destination_field: 'field5', copy_action: 'copy' },
      'field4+field6' => { source_field: 'field4', destination_field: 'field6', copy_action: 'copy' },
    }

    mutations, _, _ = generate_logstash_pipeline(mapping)

    assert_equal(
      [ {"copy" => {"[field1]" => "[field3]"}}, 
        {"copy" => {"[field2]" => "[field3]"}}, 
        {"copy" => {"[field4]" => "[field5]"}}, 
        {"copy" => {"[field4]" => "[field6]"}}],
      mutations
    )
  end

  def test_dates
    mapping = {
      'field1+@timestamp' =>
        { source_field: 'field1',
          destination_field: '@timestamp',
          format_action: 'parse_timestamp',
          timestamp_format: 'UNIX_MS' },
      'field2+@timestamp' =>
        { source_field: 'field2',
          destination_field: '@timestamp',
          format_action: 'parse_timestamp',
          timestamp_format: 'UNIX' },
    }

    mutations, dates, array_fields = generate_logstash_pipeline(mapping)

    assert_equal(
      [],
      mutations
    )

    assert_equal(
      [],
      array_fields
    )

    assert_equal(
      {"date" => {
        "match" => ["[field1]", "UNIX_MS"],
        "target" => "[@timestamp]"
      }},
      dates[0]
    )

    assert_equal(
      {"date" => {
        "match" => ["[field2]", "UNIX"],
        "target" => "[@timestamp]"
      }},
      dates[1]
    )

  end
end
