def same_field_name?(row)
  return  row[:destination_field].nil? ||
          row[:source_field] == row[:destination_field]
end
