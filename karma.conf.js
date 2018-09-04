module.exports = function(config) {
	config.set({

		// autoWatch: false, // moved into pakcage.json script option

		basePath: './',

		browsers: ['PhantomJS'],

		files: [
			'node_modules/angular/angular.js',
			'node_modules/angular-animate/angular-animate.js',
			'node_modules/angular-aria/angular-aria.js',
			'node_modules/angular-mocks/angular-mocks.js',
			'node_modules/angular-sanitize/angular-sanitize.js',
			'node_modules/materia-client-assets/dist/js/materia.js',
			'node_modules/materia-client-assets/dist/js/student.js',
			'node_modules/materia-client-assets/dist/js/author.js',
			'build/demo.json',
			'build/assets/creator-assets/*.js',
            'build/assets/player-assets/*.js',
            'build/assets/*.js',
            'build/*.js',
			'tests/*.js'
		],

		frameworks: ['jasmine'],

		plugins: [
			'karma-coverage',
			'karma-jasmine',
			'karma-json-fixtures-preprocessor',
			'karma-mocha-reporter',
			'karma-phantomjs-launcher'
		],

		preprocessors: {
			'build/*.js': ['coverage'],
			'build/demo.json': ['json_fixtures']
		},

		// singleRun: true, // moved into pakcage.json script option

		//plugin-specific configurations

		jsonFixturesPreprocessor: {
			variableName: '__demo__'
		},

		reporters: ['coverage', 'mocha'],

		//reporter-specific configurations

		coverageReporter: {
			check: {
				global: {
					statements: 100,
					branches:   80,
					functions:  90,
					lines:      90
				},
				each: {
					statements: 100,
					branches:   80,
					functions:  90,
					lines:      90
				}
			},
			reporters: [
				{ type: 'html', subdir: 'report-html' },
				{ type: 'cobertura', subdir: '.', file: 'coverage.xml' }
			]
		},

		mochaReporter: {
			output: 'autowatch'
		}

	});

};
