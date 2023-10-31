angular.module('AdventureScorescreen', ['ngSanitize'])

## CONTROLLER ##
.controller 'AdventureScoreCtrl', ['$scope','$sanitize', '$sce', ($scope, $sanitize, $sce) ->

	materiaCallbacks = {}

	$scope.inventory = []
	$scope.responses = []
	$scope.itemSelection = []
	$scope.customTable = false

	$scope.setSelectedItem = (item) ->
		$scope.selectedItem = item

	$scope.getItemIndex = (item) ->
		if (item)
			for i, index in $scope.itemSelection
				if i.id is item.id
					return index

	$scope.getQuestion = (qset, id) ->
		for i in qset.items
			if i.id is id
				return i
		return -1

	$scope.createInventoryFromResponses = (qset, responses) ->
		inventory = []

		for r, index in responses
			for responseItem in $scope.getQuestion(qset, r.data[1]).options.items
				itemPresent = false
				for item in inventory
					if item.id is responseItem.id
						item.count += responseItem.count
						itemPresent = true
				if !itemPresent
					inventory.push(responseItem)

		return inventory

	$scope.createTable = (qset, scoreTable) ->
		table = []
		for response in scoreTable
			items = $scope.getQuestion(qset, response.data[1]).options.items
			row =
				question: response.data[0]
				answer: response.data[2]
				feedback: response.feedback
				items: $scope.getQuestion(qset, response.data[1]).options.items
				gainedItems: if items.some((i) => i.count > 0) then true else false
				lostItems: if items.some((i) => i.count < 0) then true else false
			table.push(row)
		return table


	$scope.toggleInventoryDrawer = () ->
		$scope.showInventory = !$scope.showInventory

	materiaCallbacks.start = (instance, qset, scoreTable, isPreview, qsetVersion) ->
		$scope.$apply ->
			# console.log(instance)
			# console.log(qset)
			# console.log(scoreTable)
			# $scope.inventory = $scope.createInventoryFromResponses(qset, scoreTable)
			# $scope.itemSelection = qset.options.inventoryItems || []
			# $scope.table = $scope.createTable(qset, scoreTable)
			# console.log($scope.inventory)
			# console.log($scope.itemSelection)
			# console.log($scope.table)

			$scope.customTable = false

	# Materia.ScoreCore.hideResultsTable()

	return Materia.ScoreCore.start materiaCallbacks

]

angular.bootstrap(document, ['AdventureScorescreen'])