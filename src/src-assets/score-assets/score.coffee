angular.module('Adventure', ['ngSanitize'])

.controller 'AdventureScoreCtrl', ['$scope','$sanitize', '$sce', '$timeout', 'inventoryService', 'legacyQsetSrv', ($scope, $sanitize, $sce, $timeout, inventoryService, legacyQsetSrv) ->

	$scope.responses = []
	$scope.itemSelection = []
	$scope.customTable = false
	$scope.showOlderQsetWarning = false

	_qsetItems = []
	_currentInventory = []

	_getHeight = () ->
		Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).height))

	_getItemInInventory = (id) ->
		for item in _currentInventory
			if item.id is id then return item

		return null

	# recency is determined by the order in which a node a visited
	# unlike the player, which determines recency by time
	_getMostRecentItem = (requiredItems) ->
		mostRecentItem = 0
		for i in _currentInventory
			for r in requiredItems
				if i.id is r.id
					if i.recency > mostRecentItem
						mostRecentItem = i.recency
		mostRecentItem

	_getAnswerById = (question, id) ->
		for answer in question.answers
			if answer.id is id then return answer

	# in order to accurately simulate the items received and taken, we have to recreate item handling logic in the score screen
	# simply using the options.items value for each question would not accurately report items taken and received
	# if certain factors are at play, like the takeAll and firstVisitOnly flags
	_manageItemDelta = (question) ->

		items = []

		if !question.options.items then return items

		for item in question.options.items
			if item.firstVisitOnly and inventoryService.getNodeVisitedCount() > 0 then continue

			# positive delta? Add the item to the inventory, or increase the count if it's in there already
			if item.count > 0

				previouslyExists = false
				# if the item type is already in the inventory, increase the count
				for inventoryItem in _currentInventory
					if inventoryItem.id is item.id
						inventoryItem.count += item.count
						inventoryItem.recency = inventoryService.recencyCounter
						previouslyExists = true
						break

				# add the item to the inventory, since it wasn't there already
				if !previouslyExists
					itemCopy = angular.copy item
					itemCopy.recency = inventoryService.recencyCounter
					_currentInventory.push angular.copy itemCopy

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

		inventoryService.addNodeToVisited question

		return items

	_getQuestion = (qset, id) ->
		for i in qset.items
			if i.id is id then return i
		return null

	_getQuestionByNodeId = (qset, nodeId) ->
		for i in qset.items
			if i.options.id is parseInt(nodeId) then return i
		return null

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
				question = _getQuestionByNodeId qset, response.node_id
				rowQuestion = response.data[0]
				if question.options.additionalQuestions
					rowQuestion = inventoryService.selectQuestion question, _currentInventory, inventoryService.visitedNodes
				row =
					text: rowQuestion.text
					# text:  _manageConditionalQuestion question, response.data[0] # needs to work with conditional questions
					score: response.data[1]
					type: if response.blank_node then 'blank' else 'end'
				table.push row

				$scope.showOlderQsetWarning = response.older_qset
			else
				question = _getQuestion qset, response.id
				items = if question.options.items then question.options.items else []
				rowQuestion = response.data[0]
				if question.options.additionalQuestions and question.options.additionalQuestions.length > 0
					rowQuestion = inventoryService.selectQuestion question, _currentInventory, inventoryService.visitedNodes
				row =
					question: rowQuestion.text
					# question: _manageConditionalQuestion question, response.data[0]
					answer: response.data[1]
					type: question.options.type
					feedback: response.feedback
					items: _manageItemDelta question
					gainedItems: if items.some((i) => i.count > 0) then true else false
					lostItems: if items.some((i) => i.count < 0) then true else false

				if question.options.type is 'hotspot'

					if response.data[2]
						answer = _getAnswerById(question, response.data[2])

						# older qsets won't contain an asset.url value
						image = if question.options.asset.url then question.options.asset.url else Materia.ScoreCore.getMediaUrl question.options.asset.id

						if answer
							row.svg = answer.options.svg
							row.image = image

				inventoryService.recencyCounter++
				table.push row

		return table

	# $scope.mmd_parse = (text) ->
	# 	console.log 'haha butts'
	# 	return micromarkdown.parse text

	$scope.start = (instance, qset, scoreTable, isPreview, qsetVersion) ->
		$scope.update(qset, scoreTable)

	$scope.update = (qset, scoreTable) ->

		# if a legacy qset - convert it first
		if qset.items[0].items then qset = JSON.parse legacyQsetSrv.convertOldQset qset

		$scope.$apply ->
			$scope.table = $scope.createTable(qset, scoreTable)
			_currentInventory = []
			_qsetItems = if qset.options and qset.options.inventoryItems then qset.options.inventoryItems else []

		Materia.ScoreCore.setHeight(_getHeight())

	Materia.ScoreCore.hideResultsTable()

	Materia.ScoreCore.start $scope

]