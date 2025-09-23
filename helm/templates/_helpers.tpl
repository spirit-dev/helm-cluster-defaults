{{/*
Expand the name of the chart.
*/}}
{{- define "cluster-defaults.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cluster-defaults.fullname" -}}
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
{{- define "cluster-defaults.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-defaults.labels" -}}
helm.sh/chart: {{ include "cluster-defaults.chart" . }}
{{ include "cluster-defaults.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.commonLabels}}
{{ toYaml .Values.global.commonLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cluster-defaults.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-defaults.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Priority Classes Helper - Generate priority classes for a category
*/}}
{{- define "cluster-defaults.priorityClasses" -}}
{{- $root := .root }}
{{- range $name, $config := .classes }}
{{- if and $config.value $config.description }}
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: {{ $name }}
  labels:
    {{- include "cluster-defaults.labels" $root | nindent 4 }}
    app.kubernetes.io/component: priority-class
value: {{ $config.value }}
globalDefault: {{ default false $config.globalDefault }}
description: {{ $config.description | quote }}
{{- end }}
{{- end }}
{{- end }}
