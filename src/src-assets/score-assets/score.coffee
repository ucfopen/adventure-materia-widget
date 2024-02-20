angular.module('AdventureScorescreen', ['ngSanitize'])

.controller 'AdventureScoreCtrl', ['$scope','$sanitize', '$sce', '$timeout', ($scope, $sanitize, $sce, $timeout) ->

	_getHeight = () ->
		Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).height))

	$scope.inventory = []
	$scope.responses = []
	$scope.itemSelection = []
	$scope.customTable = false

	getAnswerById = (question, id) ->
		for answer in question.answers
			if answer.id is id then return answer

	$scope.getQuestion = (qset, id) ->
		for i in qset.items
			if i.id is id
				return i
		return -1

	$scope.getItemById = (id) ->
		for item in $scope.inventory
			if item.id == id then return item
		null

	$scope.getItemUrl = (id) ->
		for item in $scope.inventory
			if item.id == id && item.icon then return item.icon.url

	$scope.createTable = (qset, scoreTable) ->
		table = []
		for response in scoreTable
			if response.type == 'SCORE_FINAL_FROM_CLIENT'
				row =
					text: response.data[0]
					score: response.data[1]
					type: 'end'
				table.push row
			else 
				question = $scope.getQuestion qset, response.id
				console.log(question)
				items = question.options.items
				row =
					question: response.data[0]
					answer: response.data[1]
					type: question.options.type
					feedback: response.feedback
					items: question.options.items
					gainedItems: if items.some((i) => i.count > 0) then true else false
					lostItems: if items.some((i) => i.count < 0) then true else false

				if question.options.type is 'hotspot'

					if response.data[2]
						answer = getAnswerById(question, response.data[2])
						if answer
							row.svg = answer.options.svg
							row.image = question.options.asset.url
				
				table.push row
		return table

	$scope.start = (instance, qset, scoreTable, isPreview, qsetVersion) ->
		$scope.update(qset, scoreTable)

	$scope.update = (qset, scoreTable) ->
		$scope.$apply ->
			$scope.table = $scope.createTable(qset, scoreTable)
			$scope.inventory = if qset.options and qset.options.inventoryItems then qset.options.inventoryItems else []
			console.log $scope.table
			console.log $scope.inventory
		
		Materia.ScoreCore.setHeight(_getHeight())
	
	Materia.ScoreCore.hideResultsTable()

	Materia.ScoreCore.start $scope

]