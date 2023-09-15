{{/*
Expand the name of the chart.
*/}}
{{- define "vikunja.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vikunja.fullname" -}}
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
{{- define "vikunja.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vikunja.labels" -}}
helm.sh/chart: {{ include "vikunja.chart" . }}
{{ include "vikunja.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vikunja.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vikunja.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .Values.extraLabels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Selector labels for API
*/}}
{{- define "vikunja.apiSelectorLabels" -}}
{{ include "vikunja.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Selector labels for frontend
*/}}
{{- define "vikunja.frontendSelectorLabels" -}}
{{ include "vikunja.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vikunja.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vikunja.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
API fullname
*/}}
{{- define "vikunja.apiFullname" -}}
{{- include "vikunja.fullname" . | printf "%s-api" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Frontend fullname
*/}}
{{- define "vikunja.frontendFullname" -}}
{{- include "vikunja.fullname" . | printf "%s-frontend" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the PVC to use
*/}}
{{- define "vikunja.pvcName" -}}
{{- default (include "vikunja.fullname" .) .Values.api.persistence.name }}
{{- end }}