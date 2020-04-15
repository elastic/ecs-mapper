require 'csv'

REQUIRED_CSV_HEADERS  = ['source_field', 'destination_field']
KNOWN_CSV_HEADERS     = REQUIRED_CSV_HEADERS + ['format_action', 'copy_action']
ACCEPTED_FORMAT_ACTIONS = ['uppercase', 'lowercase', 'to_boolean', 'to_integer',
                           'to_float', 'to_array', 'to_string'].sort

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
            row['source_field'].strip.empty? ||
            row['destination_field'].nil? ||
            row['destination_field'].strip.empty?

    # Only read supported fields, ignore the rest
    source_field = row['source_field'].strip
    dest_field = row['destination_field'].strip

    mapping[source_field + '+' + dest_field] = {
      source_field:       source_field,
      destination_field:  dest_field,
      # optional fields
      copy_action:             (row['copy_action'] && row['copy_action'].strip),
      format_action:      (row['format_action'] && row['format_action'].strip),
    }
  end
  return mapping
end

def make_mapping_explicit(raw_mapping, options)
  mapping = {}
  raw_mapping.each_pair do |key, row|
    mapping[key] = row.dup
    mapping[key][:copy_action] ||= options[:copy_action]
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
