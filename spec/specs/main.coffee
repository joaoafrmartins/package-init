describe 'PackageInit', () ->

  it 'before', () ->

    kosher.shell

    kosher.alias 'fixtures', kosher.spec.fixtures

    kosher.mock()

    kosher.alias 'APackageInit', kosher.fixtures['a-package-init'].lib.main

  describe 'properties', () ->

    describe 'context', () ->

      it 'should have a context object property', () ->

        kosher.APackageInit.context.should.be.Object

    describe 'runtimeConfig', () ->

      it 'should have a runtimeConfig string property', () ->

        kosher.APackageInit.runtimeConfig.should.be.String

      it 'should be a file', () ->

        expect(test("-f", kosher.APackageInit.runtimeConfig)).to.be.ok

  describe 'methods', () ->

    it 'before', () ->

      kosher.alias 'instance', kosher.APackageInit

      kosher.methods "run", "apply", "prompt", "query"
