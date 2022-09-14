AdventureScorescreen = angular.module('AdventureScorescreen', ['ngSanitize'])

## CONTROLLER ##
AdventureScorescreen.controller 'AdventureScoreCtrl', ['$scope','$sanitize', '$sce', ($scope, $sanitize, $sce) ->

	materiaCallbacks = {}

	$scope.inventory = []

	$scope.setSelectedItem = (item) ->
		$scope.selectedItem = item
	
	materiaCallbacks.start = (instance, qset, scoreTable, isPreview, qsetVersion) ->
		console.log(qset)
		$scope.inventory = qset.options.inventoryItems

	Materia.ScoreCore.start materiaCallbacks

]