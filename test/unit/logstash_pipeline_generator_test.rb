require 'minitest/autorun'
require_relative '../../lib/logstash_pipeline_generator'

class LogstashPipelineGeneratorTest < Minitest::Test
  def test_logstash_pipeline
    mapping = {
      'old1' => { source_field: 'old1', destination_field: 'new1', rename: 'copy' },
      'old2' => { source_field: 'old2', destination_field: 'new2', rename: 'rename' },
      'old3' => { source_field: 'old3', destination_field: 'new3', rename: 'copy' },
    }
    mutations, array_fields = generate_logstash_pipeline(mapping)
    old1_processor = mutations[0]
    old2_processor = mutations[1]
    old3_processor = mutations[2]
    assert_equal( { 'copy'   => { '[old1]' => '[new1]' } }, old1_processor)
    assert_equal( { 'rename' => { '[old2]' => '[new2]' } }, old2_processor)
    assert_equal( { 'copy'   => { '[old3]' => '[new3]' } }, old3_processor)
  end

  def test_non_renamed_ls
    mapping = {
      'field1' => { source_field: 'field1', destination_field: 'field1', rename: 'copy' },
      'field2' => { source_field: 'field2', destination_field: nil, rename: 'copy' },
    }
    mutations, array_fields = generate_logstash_pipeline(mapping)
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
end
