const fs = require('fs')
const path = require('path')
const srcPath = path.join(process.cwd(), 'src') + path.sep
const outputPath = path.join(process.cwd(), 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const marked = require('meta-marked')

// grab original copyList - we're going to append to it and overwrite the default copyList
let copyList = widgetWebpack.getDefaultCopyList()

const rules = widgetWebpack.getDefaultRules()

// Append the new items we want copied
copyList.push(
	{
		from: `${srcPath}_exports/`,
		to: `${outputPath}_exports`,
	},
	{
		from: `${__dirname}/node_modules/micromarkdown/dist/micromarkdown.min.js`,
		to: `${outputPath}assets/micromarkdown.min.js`,
	},
	{
		from: `${srcPath}/_helper-docs/assets`,
		to: `${outputPath}/guides/assets`,
		toType: 'dir'
	},
	)

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
	],
	"guides/guideStyles.css": [
		srcPath+"_helper-docs/guideStyles.scss"
	]
}

const babelLoaderWithPolyfillRule = {
	test: /\.js$/,
	exclude: /node_modules/,
	use: {
		loader: 'babel-loader',
		options: {
			presets: [
				'@babel/preset-env',
				{
					targets: {
					browsers: [
						">0.25%",
						"not ie 10",
						"not op_mini all"
					]
					},
				}
			]
		}
	}
}

const moduleRules = [
	rules.loaderCompileCoffee,
	babelLoaderWithPolyfillRule,
	rules.copyImages,
	rules.loadHTMLAndReplaceMateriaScripts,
	rules.loadAndPrefixCSS,
	rules.loadAndPrefixSASS,
]

let options = {
	entries,
	copyList,
	moduleRules
}

const generateHelperPlugin = name => {
	const file = fs.readFileSync(path.join(__dirname, 'src', '_helper-docs', name+'.md'), 'utf8')
	const content = marked(file)

	return new HtmlWebpackPlugin({
		template: path.join(__dirname, 'src', '_helper-docs', 'helperTemplate'),
		filename: path.join(outputPath, 'guides', name+'.html'),
		title: name.charAt(0).toUpperCase() + name.slice(1),
		chunks: ['guides'],
		content: content.html
	})
}

let build = widgetWebpack.getLegacyWidgetBuildConfig(options)
build.plugins.unshift(generateHelperPlugin('creator'))
build.plugins.unshift(generateHelperPlugin('player'))

// load the reusable legacy webpack config from materia-widget-dev
module.exports = build
