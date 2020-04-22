require 'csv'

REQUIRED_CSV_HEADERS = [
    'source_field', 
    'destination_field'
]

KNOWN_CSV_HEADERS = REQUIRED_CSV_HEADERS + [
    'format_action', 
    'copy_action',
    'timestamp_format'
]

ACCEPTED_FORMAT_ACTIONS = [
    'uppercase', 
    'lowercase', 
    'to_boolean', 
    'to_integer',
    'to_float', 
    'to_array', 
    'to_string',
    'parse_timestamp',
].sort

def read_csv(file_name)
  csv = CSV.read(file_name, headers: true)
  unless (REQUIRED_CSV_HEADERS - csv.headers).empty?
    abort "Required headers are missing in the CSV.\n" +
          "  Missing: #{REQUIRED_CSV_HEADERS - csv.headers}.\n" +
          "  Required: #{REQUIRED_CSV_HEADERS}.\n" +
          "  Found: #{csv.headers}"
  end
  return csv_to_mapping(csv)
end

def csv_to_mapping(csv)
  mapping = {}
  csv.each do |row|
    # skip rows that don't have a source field
    next if row['source_field'].nil? ||
            row['source_field'].strip.empty? 

    # skip if no destination field and no format field provided
    # since it's possible to reformat a source field by itself
    next if ( row['destination_field'].nil? ||
              row['destination_field'].strip.empty? ) and
            ( row['format_field'].nil? ||
              row['format_field'].strip.empty? )

    source_field = row['source_field'].strip
    destination_field =   row['destination_field'] && row['destination_field'].strip || ''
 
    mapping[source_field + '+' + destination_field] = {
      # required fields
      source_field:       source_field,
      destination_field:  destination_field,
      # optional fields
      copy_action:        (row['copy_action'] && row['copy_action'].strip),
      format_action:      (row['format_action'] && row['format_action'].strip),
      timestamp_format:   (row['timestamp_format'] && row['timestamp_format'].strip),
    }
  end
  return mapping
end

def make_mapping_explicit(raw_mapping, options)
  mapping = {}
  raw_mapping.each_pair do |key, row|
    mapping[key] = row.dup
    mapping[key][:copy_action] ||= options[:copy_action]

    # If @timestamp is the destination and the user does not
    # specify how to format the conversion, assume we're 
    # converting it to UNIX_MS
    if mapping[key][:destination_field] == '@timestamp' and 
        ( mapping[key][:timestamp_format].nil? || 
          mapping[key][:timestamp_format].strip.empty? )
        mapping[key][:format_action] = 'parse_timestamp'
        mapping[key][:timestamp_format] = 'UNIX_MS'

    # If the destination field is empty but a format action is
    # provided, then assume we're formating the source field.
    elsif ( mapping[key][:destination_field].nil? || 
            mapping[key][:destination_field].strip.empty? ) and not
          ( mapping[key][:format_action].nil? ||
            mapping[key][:format_action].strip.empty? )
        puts mapping[key][:source_field].inspect
        mapping[key][:destination_field] = mapping[key][:source_field]
    end
  end
  validate_mapping!(mapping)
  return mapping
end

def validate_mapping!(mapping)
  mapping.each_pair do |key, row|
    if row[:format_action] and not ACCEPTED_FORMAT_ACTIONS.include?(row[:format_action])
      raise "Unsupported format_action: #{row[:format_action]}, expected one of #{ACCEPTED_FORMAT_ACTIONS}"
    end
  end
end
