kosher.mock

  module: 'inquirer',

  mock:

    "prompt": (prompts, callback) ->

      context = {}

      for prompt in prompts

        if prompt.default then value = prompt.default or prompt.default()

        else if prompt.type is "input" then value = "string"

        else if prompt.type is "confirm" then value = true

        else value = []

        context[prompt.name] = value

      callback context
