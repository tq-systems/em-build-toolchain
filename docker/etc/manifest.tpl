{{ range . }}
name:     {{.Name}}
version:  {{.Version}}
license:  {{.LicenseName}}
{{``}}
{{- end }}
