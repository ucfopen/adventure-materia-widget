AdventureScorescreen = angular.module('AdventureScorescreen', ['ngSanitize'])

## CONTROLLER ##
AdventureScorescreen.controller 'AdventureScoreCtrl', ['$scope','$sanitize', '$sce', ($scope, $sanitize, $sce) ->

	materiaCallbacks = {}

	$scope.inventory = []
	$scope.itemSelection = []

	$scope.setSelectedItem = (item) ->
		$scope.selectedItem = item

	$scope.getItemIndex = (item) ->
		for i, index in $scope.itemSelection
			if i.id is item.id
				return index
	
	materiaCallbacks.start = (instance, qset, scoreTable, isPreview, qsetVersion) ->
		console.log(qset)
		console.log(scoreTable)
		console.log(instance)
		$scope.itemSelection = qset.options.inventoryItems
		$scope.inventory = qset.options.inventoryItems

	Materia.ScoreCore.start materiaCallbacks

]