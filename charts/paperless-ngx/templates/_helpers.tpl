{{/*
Expand the name of the chart.
*/}}
{{- define "paperless.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "paperless.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified redis app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "paperless.redis.fullname" -}}
{{- printf "%s-redis" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "paperless.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image name that is used in the deployment
*/}}
{{- define "paperless.image" -}}
{{- if .Values.paperless.image.tag -}}
{{- printf "%s:%s" .Values.paperless.image.repository .Values.paperless.image.tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.paperless.image.repository .Chart.AppVersion -}}
{{- end -}}
{{- end -}}

{{/*
Create image name that is used in the deployment
*/}}
{{- define "gotenberg.image" -}}
{{- printf "%s:%s" .Values.gotenberg.image.repository .Values.gotenberg.image.tag -}}
{{- end -}}

{{/*
Create image name that is used in the deployment
*/}}
{{- define "tika.image" -}}
{{- printf "%s:%s" .Values.tika.image.repository .Values.tika.image.tag -}}
{{- end -}}

{{- define "paperless.ingress.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- end -}}

{{/*
Create environment variables used to configure the paperless containers.
*/}}
{{- define "paperless.env" -}}
{{- if .Values.mariadb.enabled }}
- name: PAPERLESS_DBENGINE
  value: "mariadb"
- name: PAPERLESS_DBHOST
  value: {{ template "mariadb.primary.fullname" .Subcharts.mariadb }}
- name: PAPERLESS_DBNAME
  value: {{ .Values.mariadb.auth.database | quote }}
- name: PAPERLESS_DBNAME
  value: "3306"
- name: PAPERLESS_DBUSER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.usernameKey }}
- name: PAPERLESS_DBPASS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.passwordKey }}
{{- else if .Values.postgresql.enabled }}
- name: PAPERLESS_DBENGINE
  value: "postgresql"
- name: PAPERLESS_DBHOST
  value: {{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
- name: PAPERLESS_DBNAME
  {{- if .Values.postgresql.auth.database }}
  value: {{ .Values.postgresql.auth.database | quote }}
  {{ else }}
  value: {{ .Values.postgresql.global.postgresql.auth.database | quote }}
  {{- end }}
- name: PAPERLESS_DB_PORT
  value: "5432"
- name: PAPERLESS_DBUSER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.usernameKey }}
- name: PAPERLESS_DBPASS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.passwordKey }}
{{- else }}
  {{- if eq .Values.externalDatabase.type "postgresql" }}
- name: PAPERLESS_DBHOST
  {{- if .Values.externalDatabase.existingSecret.hostKey }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.hostKey }}
  {{- else }}
  value: {{ .Values.externalDatabase.host | quote }}
  {{- end }}
- name: PAPERLESS_DBNAME
  {{- if .Values.externalDatabase.existingSecret.databaseKey }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.databaseKey }}
  {{- else }}
  value: {{ .Values.externalDatabase.database | quote }}
  {{- end }}
- name: PAPERLESS_DBUSER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.usernameKey }}
- name: PAPERLESS_DBPASS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.passwordKey }}
  {{- else }}
- name: PAPERLESS_DBENGINE
  value: {{ .Values.externalDatabase.type | quote }}
- name: PAPERLESS_DBHOST
  {{- if .Values.externalDatabase.existingSecret.hostKey }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.hostKey }}
  {{- else }}
  value: {{ .Values.externalDatabase.host | quote }}
  {{- end }}
- name: PAPERLESS_DBNAME
  {{- if .Values.externalDatabase.existingSecret.databaseKey }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.databaseKey }}
  {{- else }}
  value: {{ .Values.externalDatabase.database | quote }}
  {{- end }}
- name: PAPERLESS_DBPORT
  value: {{ .Values.externalDatabase.port | quote }}
- name: PAPERLESS_DBUSER
  {{- if .Values.externalDatabase.existingSecret.enabled }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.usernameKey }}
  {{- else }}
  value: {{ .Values.externalDatabase.user | quote }}
  {{- end }}
- name: PAPERLESS_DBPASS
  {{- if .Values.externalDatabase.existingSecret.enabled }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret.secretName | default (printf "%s-db" .Release.Name) }}
      key: {{ .Values.externalDatabase.existingSecret.passwordKey }}
  {{- else }}
  value: {{ .Values.externalDatabase.password | quote }}
  {{- end }}
  {{- end }}
{{- end }}
- name: PAPERLESS_URL
  {{- if .Values.ingress.tls }}
  value: {{ printf "https://%s" .Values.paperless.host | quote }}
  {{ else }}
  value: {{ printf "http://%s" .Values.paperless.host | quote }}
  {{- end }}
- name: PAPERLESS_PORT
  value: {{ .Values.paperless.containerPort | quote }}
{{- if .Values.redis.enabled }}
- name: PAPERLESS_REDIS
  value: {{ printf "redis://%s-redis-master:%v" .Release.Name .Values.redis.master.service.ports.redis }}
{{- end }}
{{- if .Values.tika.enabled }}
- name: PAPERLESS_TIKA_ENABLED
  value: "1"
- name: PAPERLESS_TIKA_ENDPOINT
  value: {{ printf "http://%s-tika:%v" .Release.Name .Values.tika.service.port | quote  }}
- name: PAPERLESS_TIKA_GOTENBERG_ENDPOINT
  value: {{ printf "http://%s-gotenberg:%v" .Release.Name .Values.gotenberg.service.port | quote  }}
{{- end }}
{{- if .Values.paperless.extraEnv }}
{{ toYaml .Values.paperless.extraEnv }}
{{- end }}
{{- end -}}
