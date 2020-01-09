require_relative 'helpers'

def generate_logstash_pipeline(mapping)
  mutations = [] # Most things are in the same mutate block
  array_fields = []
  mapping.each_pair do |source_field, row|
    if same_field_name?(row)
      next if row[:format_action].nil?
    end
    if row[:destination_field]
      if 'copy' == row[:rename]
        mutations << { 'copy' => { lsf(source_field) => lsf(row[:destination_field]) } }
      else
        mutations << { 'rename' => { lsf(source_field) => lsf(row[:destination_field]) } }
      end
    end

    if row[:format_action]
      affected_field = row[:destination_field] || row[:source_field]
      type = case row[:format_action]
             when 'to_boolean'
               'boolean'
             when 'to_integer'
               'integer'
             when 'to_string'
               'string'
             when 'to_float'
               'float'
             end
      if type
        mutations << { 'convert' => { lsf(affected_field) => type } }
      elsif 'uppercase' == row[:format_action]
        mutations << { 'uppercase' => [lsf(affected_field)] }
      elsif 'lowercase' == row[:format_action]
        mutations << { 'lowercase' => [lsf(affected_field)] }
      elsif 'to_array' == row[:format_action]
        array_fields << lsf(affected_field)
      end
    end
  end
  return mutations, array_fields
end

def render_mutate_line(line)
  raise "Expected one key at root of #{line}" if line.keys.size != 1
  action = line.keys.first
  if line[action].is_a? Hash
    key, value = line[action].to_a.flatten
    return "#{action} => { '#{key}' => '#{value}' }"
  elsif line[action].is_a? Array
    return "#{action} => [ '#{line[action].first}' ]"
  end
end

def lsf(field)
  field.split('.').map{|f| "[#{f}]"}.join
end

def output_logstash_pipeline(mutations, array_fields, output_dir)
  file_name = output_dir.join('logstash.conf')
  File.open(file_name, 'w') do |f|

    f.write(<<-CONF)
filter {
  mutate {
    #{mutations.map{|line| render_mutate_line(line)}.join("\n    ")}
  }
CONF

    array_fields.each do |array_field|
      f.write(<<-RB)
  if #{array_field} {
    ruby {
      code => "event.set('#{array_field}', Array(event.get('#{array_field}')) )"
    }
  }
RB
    end
    f.write("}\n")
  end
  return file_name
end
