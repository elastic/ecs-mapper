⚠️ **This tool and repository are no longer maintained. We strongly advise you to [use Kibana to map custom data to ECS fields](https://www.elastic.co/guide/en/ecs/current/ecs-converting.html) instead.**

---

## Synopsis

The ECS mapper tool turns a field mapping from a CSV to an equivalent pipeline for:

- [Beats](https://www.elastic.co/guide/en/beats/filebeat/current/filtering-and-enhancing-data.html)
- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest-processors.html)
- [Logstash](https://www.elastic.co/guide/en/logstash/current/filter-plugins.html)

This tool generates starter pipelines for each solution above to help you 
get started quickly in mapping new data sources to ECS.

A mapping CSV is what you get when you start planning how to map a new data
source to ECS in a spreadsheet.

Colleagues may collaborate on a spreadsheet that looks like this:

| source\_field | destination\_field | notes  |
|--------------|-------------------|---------------------------------------|
| duration     | event.duration    | ECS supports nanoseconds precision    |
| remoteip     | source.ip         | Hey @Jane do you agree with this one? |
| message      |                   | No need to change this field          |
| ...          |                   |                                       |

You can export your spreadsheet to CSV, run it through the ECS mapper,
and generate your starter pipelines.

Note that this tool generates starter pipelines. They only do field rename and copy
operations as well as some field format adjustments. It's up to you to integrate them
in a complete pipeline that ingests and outputs the data however you need.

Scroll down to the [Examples](#examples) section below to get right to a
concrete example you can play with.

## CSV Format

Here are more details on the CSV format supported by this tool. Since mapping
spreadsheets are used by humans, it's totally fine to have as many columns
as you need in your spreadsheets/CSV. Only the following columns will be considered:

| column name | required | allowed values | notes |
|-------------|----------|----------------|-------|
| source\_field | required |  | A dotted Elasticsearch field name. Dots represent JSON nesting. Lines with empty "source\_field" are skipped. |
| destination\_field | required |  | A dotted Elasticsearch field name. Dots represent JSON nesting. Can be left empty if there's no copy action (just a type conversion). |
| format\_action | optional | to\_float, to\_integer, to\_string, to\_boolean, to\_array, parse\_timestamp, uppercase, lowercase, (empty) | Simple conversion to apply to the field value. |
| timestamp\_format | optional | Only UNIX and UNIX\_MS formats are supported across all three tools. You may also specify other formats, like ISO8601, TAI64N, or a Java time pattern, but we will not validate whether the format is supported by the tool. |
| copy\_action | optional | rename, copy, (empty) | What to do with the field. If left empty, default action is based on the `--copy-action` flag. |

You can start from this
[spreadsheet template](https://docs.google.com/spreadsheets/d/1m5JiOTeZtUueW3VOVqS8bFYqNGEEyp0jAsgO12NFkNM). Make a copy of it in your Google Docs account, or download it as an Excel file.

When the destination field is @timestamp, then we always enforce an explicit date ```format_action``` of ```parse_timestamp``` to ```UNIX_MS``` avoid conversion problems downstream. If no ```timestamp_format``` is provided, then ```UNIX_MS``` is used. Please note that the timestamp layouts used by the [Filebeat processor for converting timestamps](https://www.elastic.co/guide/en/beats/filebeat/current/processor-timestamp.html) are different than the formats supported by date processors in Logstash and Elasticsearch Ingest Node.



## Usage and Dependencies

This is a simple Ruby program with no external dependencies, other than development
dependencies.

Any modern version of Ruby should be sufficient. If you don't intend to run the
tests or the rake tasks, you can skip right to [usage tips](#using-the-ecs-mapper).

### Ruby Setup

If you want to tweak the code of this script, run the tests or use the rake tasks,
you'll need to install the development dependencies.

Once you have Ruby installed for your platform, installing the dependencies is simply:

```bash
gem install bundler
bundle install
```

Run the tests:

```bash
rake test
```

### Using the ECS Mapper

Help.

```bash
./ecs-mapper --help
Reads a CSV mapping of source field names to destination field names, and generates
Elastic pipelines to help perform the conversion.

You can have as many columns as you want in your CSV.
Only the following columns will be used by this tool:
source_field, destination_field, format_action, copy_action

Options:
    -f, --file FILE                  Input CSV file.
    -o, --output DIR                 Output directory. Defaults to parent dir of --file.
        --copy-action COPY_ACTION
                                     Default action for field renames. Acceptable values are: copy, rename. Default is copy.
        --debug                      Shorthand for --log-level=debug
    -h, --help                       Display help
```

Process my.csv and output pipelines in the same directory as the csv.

```bash
./ecs-mapper --file my.csv
```

Process my.csv and output pipelines elsewhere.

```bash
./ecs-mapper --file my.csv --output pipelines/mine/
```

Process my.csv, fields with an empty value in the "copy\_action" column are renamed,
instead of copied (the default).

```bash
./ecs-mapper --file my.csv --copy_action rename 
```

## Examples

Look at an example CSV mapping and the pipelines generated from it:

- [example/mapping.csv](example/mapping.csv)
- [example/beats.yml](example/beats.yml)
- [example/elasticsearch.json](example/elasticsearch.json)
- [example/logstash.conf](example/logstash.conf)

You can try each pipeline easily by following the instructions
in [example/README.md](example/).

## Caveats

* The Beats pipelines don't perform "to\_array", "uppercase" nor
  "lowercase" transformations. They could be implemented via the "script" processor.
* Only UNIX and UNIX\_MS timestamp formats are supported across Beats, Elasticsearch, 
  and Filebeat. For other timestamp formats, please modify the starter pipeline or add the 
  appropriate date processor in the generated pipeline by hand. Refer to the documentation
  for [Beats](https://www.elastic.co/guide/en/beats/filebeat/current/processor-timestamp.html), [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/master/date-processor.html), and [Logstash](https://www.elastic.co/guide/en/logstash/current/plugins-filters-date.html#plugins-filters-date-match).
* This tool does not currently support additional processors, like setting static 
  field values or dropping events based on a condition.
