angular.module('AdventureScorescreen', ['ngSanitize'])

.controller 'AdventureScoreCtrl', ['$scope','$sanitize', '$sce', '$timeout', ($scope, $sanitize, $sce, $timeout) ->

	$scope.responses = []
	$scope.itemSelection = []
	$scope.customTable = false

	_visitedNodes = []
	_qsetItems = []
	_currentInventory = []

	_getHeight = () ->
		Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).height))

	_getAnswerById = (question, id) ->
		for answer in question.answers
			if answer.id is id then return answer

	# in order to accurately simulate the items received and taken, we have to recreate item handling logic in the score screen
	# simply using the options.items value for each question would not accurately report items taken and received
	# if certain factors are at play, like the takeAll and firstVisitOnly flags
	_manageItemDelta = (question) ->

		items = []
		
		for item in question.options.items
			if item.firstVisitOnly and _visitedNodes.includes(question.options.id) then continue

			# positive delta? Add the item to the inventory, or increase the count if it's in there already
			if item.count > 0

				previouslyExists = false
				# if the item type is already in the inventory, increase the count
				for inventoryItem in _currentInventory
					if inventoryItem.id is item.id
						inventoryItem.count += item.count
						previouslyExists = true
						break
				
				# add the item to the inventory, since it wasn't there already
				if !previouslyExists then _currentInventory.push angular.copy item

				items.push item
			
			# negative delta? remove it from the inventory, if present
			else if item.count < 0

				for inventoryItem in _currentInventory
					if !inventoryItem then continue

					if inventoryItem.id is item.id
						itemRemoved = angular.copy item
						# takeAll ignores the count value - remove the item from the inventory altogether
						# instead of using item.count, the delta is whatever the current inventory value is, zeroed out
						if item.takeAll
							itemRemoved.count = inventoryItem.count * -1
							
							_currentInventory.splice(_currentInventory.indexOf(inventoryItem), 1)
							
						else
							# inventoryItem will persist because the quantity removed is less than the total
							if inventoryItem.count > item.count * -1
								itemRemoved.count = item.count
								inventoryItem.count += item.count
							else
								# remove the item completely, and the quantity removed will be some value less than item.count
								itemRemoved.count = (inventoryItem.count % item.count) * -1
								_currentInventory.splice(_currentInventory.indexOf(inventoryItem), 1)

						items.push itemRemoved

		_visitedNodes.push question.options.id
		if _currentInventory[0] then console.log 'the current cash count is ' + _currentInventory[0].count
		return items

	$scope.getQuestion = (qset, id) ->
		for i in qset.items
			if i.id is id
				return i
		return -1

	$scope.getItemById = (id) ->
		for item in _qsetItems
			if item.id == id then return item
		null

	$scope.getItemUrl = (id) ->
		for item in _qsetItems
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
				items = question.options.items
				row =
					question: response.data[0]
					answer: response.data[1]
					type: question.options.type
					feedback: response.feedback
					items: _manageItemDelta question
					gainedItems: if items.some((i) => i.count > 0) then true else false
					lostItems: if items.some((i) => i.count < 0) then true else false

				if question.options.type is 'hotspot'

					if response.data[2]
						answer = _getAnswerById(question, response.data[2])
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
			_currentInventory = []
			_qsetItems = if qset.options and qset.options.inventoryItems then qset.options.inventoryItems else []
		
		Materia.ScoreCore.setHeight(_getHeight())
	
	Materia.ScoreCore.hideResultsTable()

	Materia.ScoreCore.start $scope

]