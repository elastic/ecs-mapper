require 'yaml'
require_relative 'helpers'

def generate_beats_pipeline(mapping)
  # copy/rename
  fields_to_copy = []
  fields_to_rename = []
  fields_to_convert = []
  pipeline = []

  mapping.each_pair do |_, row|
    if same_field_name?(row)
      next if row[:format_action].nil?
    end

    source_field = row[:source_field]

    if row[:destination_field] and not ['parse_timestamp'].include?(row[:format_action])
      statement = {
        'from' => source_field,
        'to' => row[:destination_field],
      }
      if 'copy' == row[:copy_action]
        fields_to_copy << statement
      else
        fields_to_rename << statement
      end
    end

    if row[:format_action]
      affected_field = row[:destination_field] || row[:source_field]
      type = case row[:format_action]
             when 'to_boolean'
               'boolean'
             when 'to_integer'
               'long'
             when 'to_string'
               'string'
             when 'to_float'
               'float'
             end

      if type
        statement = { 'from' => affected_field, 'type' => type }
        fields_to_convert << statement

      elsif ['parse_timestamp'].include?(row[:format_action])
        pipeline << {
          'timestamp' => {
            'field' => row[:source_field],
            'layouts' => row[:timestamp_format],
            'timezone' => "UTC",
            'ignore_missing' => true,
            'ignore_failure' => true
          }
        }
      end
    end
  end

  if fields_to_copy.size > 0
    pipeline << {
      'copy_fields' => { 'fields' => fields_to_copy,
                    'ignore_missing' => true, 'fail_on_error' => false }
    }
  end
  if fields_to_rename.size > 0
    pipeline << {
      'rename' => { 'fields' => fields_to_rename,
                    'ignore_missing' => true, 'fail_on_error' => false }
    }
  end
  if fields_to_convert.size > 0
    pipeline << {
      'convert' => {  'fields' => fields_to_convert,
                      'ignore_missing' => true, 'fail_on_error' => false }
    }
  end

  return pipeline
end

def output_beats_pipeline(pipeline, output_dir)
  file_name = output_dir.join('beats.yml')
  File.open(file_name, 'w') do |f|
    yaml = YAML.dump({ 'processors' => pipeline})
    f.write(yaml.gsub(/^---./m, '')) # Making concatenation easier, to build a full Beats config
  end
  return file_name
end
