{ resolve, dirname } = require 'path'

#kosher.mock()

kosher.alias 'PackageInit'

class APackageInit extends kosher.PackageInit

  @namespace: "package"

  @template: resolve dirname(__dirname), 'template'

  @prompts:

    filename:

      default: "package.json"

    name:

      default: "name"

    version:

      default: "0.0.0"

module.exports = APackageInit
