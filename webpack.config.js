const path = require('path')
const ExtractTextPlugin = require('extract-text-webpack-plugin')

let srcPath = path.join(process.cwd(), 'src')
let outputPath = path.join(process.cwd(), 'build')

// load the reusable legacy webpack config from materia-widget-dev
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig()

webpackConfig.entry = {
	"assets/legacyQsetSrv.js": ["./src/assets/legacyQsetSrv.coffee"],

	"assets/creator-assets/app.js": ["./src/assets/creator-assets/app.coffee"],
	"assets/creator-assets/controllers.js": ["./src/assets/creator-assets/controllers.coffee"],
	"assets/creator-assets/directives.js": ["./src/assets/creator-assets/directives.coffee"],
	"assets/creator-assets/services.js": ["./src/assets/creator-assets/services.coffee"],

	"assets/player-assets/app.js": ["./src/assets/player-assets/app.coffee"],
	"assets/player-assets/player.js": ["./src/assets/player-assets/player.coffee"],

	"assets/creator-assets/creator.css": ["./src/creator.html", "./src/assets/creator-assets/creator.scss"],
	"assets/player-assets/player.css": ["./src/player.html", "./src/assets/player-assets/player.scss"]
};

module.exports = webpackConfig
