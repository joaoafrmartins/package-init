{ EOL } = require 'os'

{ existsSync } = require 'fs'

{ join, extname, resolve } = require 'path'

async = require 'async'

{ merge, template } = require 'lodash'

{ prompt } = require 'inquirer'

shelljs = require 'shelljs/global'

global.context = undefined

class PackageInit

  @context: defaults: {}, values: {}, result: {}

  @runtimeConfig: resolve __dirname, '..', 'package.json'

  @run: (options, callback) ->

    if typeof options is "string" then options = dest: options

    { dest, templates, interactive, data } = options

    interactive ?= true

    @interactive = interactive

    pkg = require @runtimeConfig

    available = Object.keys pkg?.templates?.optional or {}

    if existsSync resolve process.cwd(), 'package.json'

      @package = require resolve process.cwd(), 'package.json'

    @package ?= {}

    if not templates

      templates = available

      defaultTemplates = []

    else

      for name in templates

        name = name.replace /^package\-init\-/, ''

        if not pkg?.templates?.optional[name]

           return callback "invalid template #{name}", null

      defaultTemplates = templates

    @query [{

      type: "checkbox"

      name: "templates"

      message: "templates?"

      choices: templates

      default: defaultTemplates

    }], (response) =>

      series = []

      { templates } = response

      (

        Object.keys(pkg?.templates?.default or {}).concat(templates)

      ).map (template) =>

        if template.match(/^package\-init\-/) is null

          template = "package-init-#{template}"

        series.push (next) =>

          filepath = require.resolve(template)

          template = require template

          options = {}

          options.dest = dest

          options.defaults = data

          options.prompts = template.prompts or {}

          options.namespace = template.namespace

          options.template = resolve(
            filepath, '..', '..', 'template'
          )

          @apply options, next

      async.series series, callback

  @apply: (options, callback) ->

    options ?= {}

    options.values ?= {}

    options.values = merge @context.values, options.values

    options.defaults ?= {}

    options.defaults = merge @context.defaults, options.defaults

    @prompt options, (ctx, files) =>

      @context.result = merge @context.result, ctx

      global.context = @context.result

      inflection = require 'inflection'

      { camelize, capitalize, humanize, classify } = inflection

      ctx =

        context: @context.result

        capitalize: capitalize

        camelize: camelize

        classify: classify

        humanize: humanize

        inflection: inflection

      callbacks = files.map (file) =>

        return (next) =>

          file.dest = template(file.dest) ctx

          if not file.directory and not file.image

            file.contents = template(file.contents) ctx

          if test "-e", file.dest

            file.conflict = true

            if file.directory then return next null, file

            if not file.contents.length > 0 then return next null, file

            prev = cat file.dest

            cur = file.contents

            console.log file.dest, prev, cur

            if extname(file.dest) in [".json"]

              cur = JSON.stringify(
                merge(JSON.parse(prev), JSON.parse(cur)), null, 2
              )

            else if file.dest.match /\.(npm|git)+ignore$/

              if prev.indexOf(cur) is -1

                cur = [prev, cur].join EOL

            _diff = () =>

              require 'colors'

              rw = false

              conflict =  ""

              diff = require 'diff'

              parts = diff.diffChars prev, cur

              parts.forEach (part) ->

                color = if part.added

                  "green"

                else if part.removed

                  "red"

                else color = "grey"

                if color isnt "grey" then rw = true

                conflict += part.value[color]

              if not rw then return next null, file

              file.conflict = true

              @query [{

                name: "confirm"

                type: "confirm",

                message: [
                  "conflict on #{file.dest}",
                  "#{conflict}",
                  "overwrite?"
                ].join EOL

                default: true

              }], (res) ->

                if res.confirm then cur.to file.dest

                next null, file

            _diff()

          else

            if file.directory

              mkdir "-p", file.dest

              return next null, file

            else if file.image

              cp file.src, file.dest

              return next null, file

            else

              file.contents.to file.dest

              next null, file

      async.series callbacks, callback

  @prompt: (options, callback) ->

    query = []

    for name, definition of options.prompts

      if definition

        if typeof definition isnt "object" then definition = {}

        definition.name = "#{options.namespace}.#{name}"

        if options.values[definition.name] then continue

        definition.type ?= "input"

        definition.message ?= "#{definition.name.split(".").join(" ")}?"

        if options.defaults[definition.name]

          definition.default = options.defaults[definition.name]

        else if field = @package[name]

          if typeof field is "object" then field = JSON.stringify field

          definition.default = field

        query.push definition

    @query query, (ctx) =>

      ctx = merge ctx, options.values

      files = []

      find(options.template).map (file) =>

        dest = file.replace(options.template, '')

        if dest

          if test "-d", file

            files.push

              dest: join options.dest, dest

              directory: true

          else if test "-f", file

            if file.match(/\.jpg|png|gif|bmp$/i)

              return files.push

                src: file

                dest: join options.dest, dest

                image: true

                contents: true

            files.push

              src: file

              dest: join options.dest, dest

              contents: cat file

      callback ctx, files

  @query: (query, callback) ->

    if @interactive then return prompt query, callback

    response = {}

    typeDefaults =

      "input": ""

      "confirm": true

      "list": ""

      "rawlist": ""

      "checkbox": []

    query.map (question) ->

      { default: defaults, name, type } = question

      response[name] = defaults

      if typeof response[name] is "undefined"

        response[name] = typeDefaults[type]

    callback response

module.exports = PackageInit
