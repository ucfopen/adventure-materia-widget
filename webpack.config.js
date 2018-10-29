const path = require('path')
const srcPath = path.join(process.cwd(), 'src')
const outputPath = path.join(process.cwd(), 'build')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

// grab original copyList - we're going to append to it and overwrite the default copyList
let copyList = widgetWebpack.getDefaultCopyList()

// Append the new items we want copied
copyList.push({
	flatten: true,
	from: `${srcPath}/_exports/`,
	to: `${outputPath}/_exports`,
})

// completely replace the default entries with ours
const entries = {
	"assets/legacyQsetSrv.js": ["./src/src-assets/legacyQsetSrv.coffee"],
	"assets/creator-assets/app.js": ["./src/src-assets/creator-assets/app.coffee"],
	"assets/creator-assets/controllers.js": ["./src/src-assets/creator-assets/controllers.coffee"],
	"assets/creator-assets/directives.js": ["./src/src-assets/creator-assets/directives.coffee"],
	"assets/creator-assets/services.js": ["./src/src-assets/creator-assets/services.coffee"],
	"assets/player-assets/app.js": ["./src/src-assets/player-assets/app.coffee"],
	"assets/player-assets/player.js": ["./src/src-assets/player-assets/player.coffee"],
	"assets/creator-assets/creator.css": ["./src/creator.html", "./src/src-assets/creator-assets/creator.scss"],
	"assets/player-assets/player.css": ["./src/player.html", "./src/src-assets/player-assets/player.scss"]
}

let options = {
	entries,
	copyList
}

// load the reusable legacy webpack config from materia-widget-dev
module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)
