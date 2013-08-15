require 'sugar'

module.exports = Grill =

  #
  # Modules
  #
  Assetter: require './grill/assetter'
  Bower: require './grill/bower'
  Server: require './grill/server'

  #
  # Settings
  #
  settings:
    prefix: 'grill'
    assets:
      source: 'app'
      destination: 'public'
      vendor: ['vendor/*']
    server:
      port: 4000

  #
  # Factories
  #
  assetter: (grunt, environment) ->
    new Grill.Assetter grunt,
      grunt.file.expand("#{Grill.settings.assets.source}/*", Grill.settings.assets.vendor...),
      Grill.settings.assets.destination,
      Grill.config(grunt, 'config'),
      environment

  server: (grunt) ->
    new Grill.Server grunt

  config: (grunt, key) ->
    grunt.config.get "#{Grill.settings.prefix}.#{key}"

  #
  # Setup routine
  #
  setup: (grunt, settings={}) ->
    Object.merge Grill.settings, settings, true

    grunt.registerTask "#{Grill.settings.prefix}:bower", ->
      Grill.Bower.install grunt, @async()

    grunt.registerTask "#{Grill.settings.prefix}:server", ["#{Grill.settings.prefix}:server:development"]

    grunt.registerTask "#{Grill.settings.prefix}:server:development", ->
      @async()

      assetter = Grill.assetter(grunt, 'development')
      server   = Grill.server grunt

      server.start Grill.settings.server.port, (express) ->
        server.serveMiddlewares express, Grill.config(grunt, 'middlewares')
        server.serveProxied express, Grill.config(grunt, 'proxy')
        server.serveAssets express, assetter, Grill.config(grunt, 'assets.greedy')

    grunt.registerTask "#{Grill.settings.prefix}:server:production", ->
      @async()

      server = Grill.server grunt
      server.start process.env['PORT'] ? Grill.settings.server.port, (express) ->
        server.serveStatic express, Grill.settings.assets.destination, true

    grunt.registerTask "#{Grill.settings.prefix}:compile", ->
      Grill.assetter(grunt, 'production').compile(
        Grill.config(grunt, 'assets.root'),
        Grill.config(grunt, 'assets.skip') || [],
        error: (asset, msg) -> grunt.fail.fatal msg
        compiled: (asset, dest) -> grunt.log.ok "Compiled #{dest}"
      )

    grunt.registerTask "#{Grill.settings.prefix}:clean", ->
      grunt.file.delete 'public' if grunt.file.exists('public')
