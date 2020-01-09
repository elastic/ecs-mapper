## Running the Examples

Here are the instructions to run each of the example pipelines.

Note that the the example Beats and Logstash pipelines have been copied to
"example/beats/filebeat.yml" and "example/logstash/2-*.conf" respectively,
in order to produce functional configurations used in the following examples.

All commands should be run from the root of this repo.

### Elasticsearch ingest pipeline

In a Kibana console, prepare a "simulate" API call, without the array of processors:

```JS
POST _ingest/pipeline/_simulate
{ "pipeline": { "processors" :

} , "docs":
  [ { "_source":
      { "log_level": "debug", "eventid": 424242, "hostip": "192.0.2.3",
        "srcip": "192.0.2.1", "srcport": "42", "destip": "192.0.2.2", "destport": "42",
        "timestamp": "now", "action": "Testing", "duration": "1.1",
        "successful": "true", "process":{ "args": "--yolo" },
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36" 
      }
    }
  ]
}
```

Paste the full content of the example/elasticsearch.json file below `"processors":`.
It should now look like this:

```JS
POST _ingest/pipeline/_simulate
{ "pipeline": { "processors" :
[
  {
    "rename": {
      "field": "srcip",
      "target_field": "source.address",
      "ignore_missing": true
    }
  },
// ...
```

When you execute the call, you'll see the resulting event, with transformations applied:

```JSON
{
  "docs" : [
    {
      "doc" : {
        "_index" : "_index",
        "_type" : "_doc",
        "_id" : "_id",
        "_source" : {
          "process" : {
            "args" : [
              "--yolo"
            ]
          },
          "log" : {
            "level" : "DEBUG"
          },
          ...
```

## Logstash

Logstash can load multiple .conf files in alphabetical order.
We already have the generated Logstash partial pipeline copied to the
sample configuration directory "example/logstash/":

```bash
ls example/logstash/ # 1-input.conf 2-ecs-conversion.conf 3-output.conf
```

Start Logstash, using this set of sample configuration files:

```bash
$logstash_path/bin/logstash -f example/logstash/
```

Once Logstash is running, paste a sample document in Logstash' terminal:

```json
{ "log_level": "debug", "eventid": 424242, "srcip": "192.0.2.1", "srcport": 42, "destip": "192.0.2.2", "destport": 42, "hostip": "192.0.2.42", "ts": "now", "action": "Testing", "duration": "1.1", "process":{ "args": "--yolo" }, "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36" }
```

Logstash outputs the resulting event, with transformations applied:

```ruby
{
    "host" => {
        "ip" => [
            [0] "192.0.2.42"
        ]
    },
        "process" => {
        "args" => [
            [0] "--yolo"
        ]
    },
    # ...
```

## Beats

We already have a sample Filebeat configuration file based on the generated partial
pipeline, at "example/beats/filebeat.yml". This sample config file reads the sample
NDJSON log "example/log-sample.log" and outputs the converted docs to stdout.

Run Filebeat with this sample configuration file:

```bash
$filebeat_path/filebeat -c example/beats/filebeat.yml
```

You should see an output similar to:

```JSON
{
  "@timestamp": "2020-01-01T01:01:01.001Z",
  "process": {
    "args": "--yolo"
  },
  "host": {
    "ip": "192.0.2.42",
    "name": "matbook-pro.lan"
  },
  ...
```
