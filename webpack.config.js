const path = require('path')
const copyPlugin = require('copy-webpack-plugin')

const srcPath = path.join(process.cwd(), 'src')
const outputPath = path.join(process.cwd(), 'build')

// grab original copyList - we're going to append to it and overwrite the default copyList
let copyConfigList = require('materia-widget-development-kit/webpack-widget').getDefaultCopyList()
// Append the new items we want copied
copyConfigList.push({
	flatten: true,
	from: `${srcPath}/_exports/`,
	to: `${outputPath}/_exports`,
})
// Create the extra config object and provide a new copyList key:value pair
let extraCfg = {
	copyList: copyConfigList
}

// load the reusable legacy webpack config from materia-widget-dev and provide the extra cfg
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig(extraCfg)

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
