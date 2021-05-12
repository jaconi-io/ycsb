#!/usr/bin/env sh

###
# Generate teamplates that make YCSB configurable via environment variables.
###

HADOOP_VERSION="3.3.0"
HBASE_VERSION="2.4.2"

generate() {
  echo "<?xml version=\"1.0\"?>"
  echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>"

  echo "<configuration>"
  for property in $(xmlstarlet select --template --match "/configuration/property/name" --value-of "." --output " " $1); do
    ENV=$(echo $property | tr "a-z" "A-Z" | tr "." "_" | tr "-" "_" )

    # Some properties contain "[port_number]" as a placeholder. We need special handling for these.
    case "$ENV" in
      *\[PORT_NUMBER\]*)
        PROPERTY_PREFIX=$(echo "$property" | awk -F '\\\[port_number\\\]' '{print $1}')
        PROPERTY_SUFFIX=$(echo "$property" | awk -F '\\\[port_number\\\]' '{print $2}')
        ENV_PREFIX=$(echo "$ENV" | awk -F '\\\[PORT_NUMBER\\\]' '{print $1}')
        ENV_SUFFIX=$(echo "$ENV" | awk -F '\\\[PORT_NUMBER\\\]' '{print $2}')
        echo "{{- range \$k, \$v := .Env }}"
        echo "  {{- if ne (replace \$k \"$ENV_PREFIX\" \"\" 1) \$k }}" # This is roughly equivalent to strings.Contains.
        echo "  {{- if ne (replace \$k \"$ENV_SUFFIX\" \"\" 1) \$k }}" # This is roughly equivalent to strings.Contains.
        echo "  {{- \$port := replace (replace \$k \"$ENV_PREFIX\" \"\" 1) \"$ENV_SUFFIX\" \"\" 1 }}"
        echo "  <property>"
        echo "    <name>$PROPERTY_PREFIX{{ \$port }}$PROPERTY_SUFFIX</name>"
        echo "    <value>{{ \$v }}</value>"
        echo "  </property>"
        echo "  {{- end }}"
        echo "  {{- end }}"
        echo "{{- end}}"
        ;;
      *)
        echo "{{- if .Env.$ENV }}"
        echo "  <property>"
        echo "    <name>$property</name>"
        echo "    <value>{{ .Env.$ENV }}</value>"
        echo "  </property>"
        echo "{{- end }}"
        ;;
    esac
  done
  echo "</configuration>"
}

curl "https://hadoop.apache.org/docs/r${HADOOP_VERSION}/hadoop-project-dist/hadoop-common/core-default.xml" --output "core-default.xml"
generate "core-default.xml" > core-site.xml.tmpl

curl "https://hadoop.apache.org/docs/r${HADOOP_VERSION}/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml" --output "hdfs-default.xml"
generate "hdfs-default.xml" > hdfs-site.xml.tmpl

curl "https://raw.githubusercontent.com/apache/hbase/rel/${HBASE_VERSION}/hbase-common/src/main/resources/hbase-default.xml" --output "hbase-default.xml"
generate "hbase-default.xml" > hbase-site.xml.tmpl
