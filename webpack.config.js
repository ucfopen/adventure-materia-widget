const path = require('path')
const srcPath = path.join(process.cwd(), 'src') + path.sep
const outputPath = path.join(process.cwd(), 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

// grab original copyList - we're going to append to it and overwrite the default copyList
let copyList = widgetWebpack.getDefaultCopyList()

// Append the new items we want copied
copyList.push({
	from: `${srcPath}_exports/`,
	to: `${outputPath}_exports`,
})

copyList.push({
	from: `${__dirname}/node_modules/micromarkdown/dist/micromarkdown.min.js`,
	to: `${outputPath}assets/micromarkdown.min.js`,
})

// completely replace the default entries with ours
const entries = {
	"assets/legacyQsetSrv.js":[
		srcPath+"src-assets/legacyQsetSrv.coffee"
	],
	"assets/player-assets/player.js": [
		srcPath+"src-assets/player-assets/app.coffee",
		srcPath+"src-assets/player-assets/player.coffee"

	],
	"assets/creator-assets/creator.js": [
		srcPath+"src-assets/creator-assets/app.coffee",
		srcPath+"src-assets/creator-assets/services.coffee",
		srcPath+"src-assets/creator-assets/directives.coffee",
		srcPath+"src-assets/creator-assets/controllers.coffee",
	],
	"assets/creator-assets/creator.css": [
		srcPath+"creator.html",
		srcPath+"src-assets/creator-assets/creator.scss"
	],
	"assets/player-assets/player.css": [
		srcPath+"player.html",
		srcPath+"src-assets/player-assets/player.scss"
	]
}

let options = {
	entries,
	copyList
}

// load the reusable legacy webpack config from materia-widget-dev
module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)
