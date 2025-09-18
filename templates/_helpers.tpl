{{/*
Expand the name of the chart.
*/}}
{{- define "heidisql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "heidisql.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "heidisql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "heidisql.labels" -}}
helm.sh/chart: {{ include "heidisql.chart" . }}
{{ include "heidisql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "heidisql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "heidisql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "heidisql.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "heidisql.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get database password
*/}}
{{- define "heidisql.databasePassword" -}}
{{- if .Values.database.existingSecret }}
{{- printf "valueFrom:\n  secretKeyRef:\n    name: %s\n    key: %s" .Values.database.existingSecret .Values.database.secretKeys.password }}
{{- else }}
{{- .Values.database.password }}
{{- end }}
{{- end }}

{{/*
Get database username
*/}}
{{- define "heidisql.databaseUsername" -}}
{{- if .Values.database.existingSecret }}
{{- printf "valueFrom:\n  secretKeyRef:\n    name: %s\n    key: %s" .Values.database.existingSecret .