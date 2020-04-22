require 'json'
require_relative 'helpers'

def generate_elasticsearch_pipeline(mapping)
  pipeline = []
  mapping.each_pair do |_, row|
    if same_field_name?(row)
      next if row[:format_action].nil?
    end

    source_field = row[:source_field]

    # copy/rename
    if row[:destination_field] and not ['parse_timestamp'].include?(row[:format_action])
      if 'copy' == row[:copy_action]
        processor = {
          set: {
            field: row[:destination_field],
            value: '{{' + source_field + '}}',
            if: field_presence_predicate(source_field),
          }
        }

      else
        processor = {
          rename: {
            field: source_field,
            target_field: row[:destination_field],
            ignore_missing: true
          }
        }
      end
      pipeline << processor
    end

    processor = nil
    if row[:format_action]
      # Modify the source_field if there's no destination_field (no rename, just a type change)
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
        processor = {
          convert: {
            field: affected_field,
            type: type,
            ignore_missing: true,
            ignore_failure: true,
          }
        }

      elsif ['uppercase', 'lowercase'].include?(row[:format_action])
        processor = {
          row[:format_action] => {
            field: affected_field,
            ignore_missing: true,
            ignore_failure: true,
          }
        }

      elsif ['to_array'].include?(row[:format_action])
        processor = {
          'append' => {
            field: affected_field,
            value: [],
            ignore_failure: true,
            if: field_presence_predicate(affected_field),
          }
        }

      elsif ['parse_timestamp'].include?(row[:format_action])
        processor = {
          'date' => {
            field: row[:source_field],
            target_field: row[:destination_field],
            formats: [ row[:timestamp_format] ],
            timezone: "UTC",
            ignore_failure: true
          }
        }
      end

    end
    pipeline << processor if processor # Skip lower/upper and others not done by convert processor
  end
  pipeline
end

def field_presence_predicate(field)
  if '@timestamp' == field
    return "ctx.containsKey('@timestamp')"
  end
  field_levels = field.split('.')
  if field_levels.size == 1
    return "ctx.#{field} != null"
  end

  null_safe = field_levels[0..-2].map { |f| "#{f}?" }.join('.')
  return "ctx.#{null_safe}.#{field_levels.last} != null"
end

def output_elasticsearch_pipeline(pipeline, output_dir)
  file_name = output_dir.join('elasticsearch.json')
  File.open(file_name, 'w') do |f|
    f.write JSON.pretty_generate(pipeline)
  end
  return file_name
end
