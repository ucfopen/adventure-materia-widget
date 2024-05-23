angular.module('Adventure', ['ngAria', 'ngSanitize'])

## CONTROLLER ##
.controller 'AdventureController', ['$scope','$rootScope', 'inventoryService', 'legacyQsetSrv','$sanitize', '$sce', '$timeout', ($scope, $rootScope, inventoryService, legacyQsetSrv, $sanitize, $sce, $timeout) ->

	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.TRANS = "transitional"
	# $scope.RESTRICTED = "restricted"
	$scope.NARR = "narrative" # May not be required
	$scope.END = "end" # May not be required
	$scope.OVER = "over" # the imaginary node after end nodes, representing the end of the widget

	# TODO Are these really required?
	PADDING_LEFT = 20
	PADDING_TOP = 15
	CONTAINER_WIDTH = 730
	CONTAINER_HEGIHT = 650

	# Characters that need to be pre-sanitize before being run through angular's $sanitize directive
	PRESANITIZE_CHARACTERS =
		'>' : '&gt;',
		'<' : '&lt;'

	$scope.title = ""
	$scope.qset = null
	$scope.hideTitle = true # set to true by default so header doesn't flash when widget first loads
	$scope.showTutorial = true
	$scope.showInventoryBtn = false
	$scope.qsetHasInventoryItems = false
	$scope.scoringDisabled = false
	$scope.customInternalScoreMessage = "" # custom "internal score screen" message, if blank then use default
	$scope.inventory = []
	$scope.itemSelection = []

	$scope.missingRequiredItems = []
	$scope.missingRequiredItemsAltText = ""

	materiaCallbacks =
		start: (instance, qset, version = '1') ->
			#Convert an old qset prior to running the widget
			if parseInt(version) is 1 then qset = JSON.parse legacyQsetSrv.convertOldQset qset

			$scope.$apply ->
				$scope.title = instance.name
				$scope.qset = qset
				$scope.itemSelection = qset.options.inventoryItems
				$scope.startID = qset.items[0].options.id

				if qset.options.startID isnt 0 and qset.options.startID
					$scope.startID = qset.options.startID

				if qset.options.hidePlayerTitle then $scope.hideTitle = qset.options.hidePlayerTitle
				else $scope.hideTitle = false # default is to display title

				if qset.options.scoreMode and qset.options.scoreMode is "Non-Scoring"
					$scope.scoringDisabled = true
					if qset.options.internalScoreMessage then $scope.customInternalScoreMessage = qset.options.internalScoreMessage

				$scope.qsetHasInventoryItems = _qsetHasInventoryItems $scope.qset

			$scope.showTutorial = true

		manualResize: true

	$scope.questionFormat =
		fontSize: 22
		height: 220

	# Lightbox
	$scope.lightboxTarget = -1

	$scope.setLightboxTarget = (val) ->
		$scope.lightboxTarget = val
		if ($scope.lightboxTarget == -1)
			document.getElementById("inventory").removeAttribute("inert")
			document.querySelector(".container").removeAttribute("inert")
			document.querySelector(".lightbox").setAttribute("inert", "true")
			document.querySelector(".inventory-button-container").removeAttribute("inert")
		else
			document.getElementById("inventory").setAttribute("inert", "true")
			document.querySelector(".container").setAttribute("inert", "true")
			document.querySelector(".lightbox").removeAttribute("inert")
			document.querySelector(".inventory-button-container").setAttribute("inert", "true")

	$scope.lightboxZoom = 0

	$scope.setLightboxZoom = (val) ->
		$scope.lightboxZoom = val

	# Object containing properties for the hotspot label that appears on mouseover
	$scope.hotspotLabelTarget =
		text: null
		x: null
		y: null
		show: false

	# Update the screen depending on the question type (narrative, mc, short answer, hotspot, etc)
	manageQuestionScreen = (questionId) ->

		# Acquire question data based on question id
		for n in [0...$scope.qset.items.length]
			if $scope.qset.items[n].options.id is questionId
				q_data = $scope.qset.items[n]
		# MWDK changes id of first item
		if questionId is 0
			q_data = $scope.qset.items[0]

		# Remove new item alerts
		for i in $scope.inventory
			i.new = false

		$scope.addedItems = []
		$scope.removedItems = []
		$scope.inventoryUpdate = false
		$scope.questionItems = []

		# Clear inventory updates
		$scope.inventoryUpdateMessage = ""

		# Add items to player's inventory
		# if q_data.options.items and q_data.options.items[0]
		if q_data.options.items and q_data.options.items[0]

			# Format items
			if q_data.options.items
				for q_i in q_data.options.items
					do (q_i) ->
						item =
							id: q_i.id
							count: q_i.count || 1
							takeAll: q_i.takeAll || false
							firstVisitOnly: q_i.firstVisitOnly || false
							recency: inventoryService.recencyCounter
						$scope.questionItems.push item
						inventoryService.recencyCounter++

			for q_i in $scope.questionItems
				do (q_i) ->
					hasItem = false

					# Check if item is first visit only and player has visited this node before
					if (inventoryService.getNodeVisitedCount(q_data) > 0 and q_i.firstVisitOnly)
						# Move to next item
					else
						# Inventory update
						if q_i.count < 0 or q_i.takeAll
							# Only show removed items if player has the item in inventory
							if $scope.inventory.some((i) => i.id is q_i.id)
								# Can't take more than what is in player inventory
								if Math.abs(q_i.count) > i.count or q_i.takeAll
									q_i.count = -1 * i.count
								if ! $scope.itemSelection[$scope.getItemIndex(q_i.id)].isSilent
									$scope.removedItems.push(q_i)
						else
							if ! $scope.itemSelection[$scope.getItemIndex(q_i.id)].isSilent
								$scope.addedItems.push(q_i)
						# Check to see if player already has item
						# If so, just update item count
						for p_i, i in $scope.inventory
							if p_i and p_i.id
								if q_i.id is p_i.id
									hasItem = true
									p_i.count += q_i.count

						$scope.inventory = $scope.inventory.filter((p_i) -> p_i.count > 0)

						if (! hasItem)
							newItem = {
								...q_i
								new: true
							}
							$scope.inventory.push(newItem)

						$scope.inventory = $scope.inventory.filter((p_i) -> p_i.count > 0)

			if ($scope.removedItems[0] || $scope.addedItems[0])
				if !$scope.showInventoryBtn then $scope.showInventoryBtn = true
				$scope.inventoryUpdate = true
				document.getElementById("inventory-update").removeAttribute("inert")

				addedItemsExist = $scope.addedItems[0]
				removedItemsExist = $scope.removedItems[0]

				if addedItemsExist
					$scope.showNew = true
					addedItemsMessage = "#{$scope.addedItems.length} new items added: #{($scope.addedItems.map((item) -> "#{$scope.itemSelection[$scope.getItemIndex(item.id)].name} (amount: #{Math.abs(item.count)})")).join(', ')}. "
				else
					addedItemsMessage = ""

				if removedItemsExist
					removedItemsMessage = "#{$scope.removedItems.length} items removed: #{($scope.removedItems.map((item) -> "#{$scope.itemSelection[$scope.getItemIndex(item.id)].name} (amount: #{Math.abs(item.count)})")).join(', ') }. "
				else
					removedItemsMessage = ""

				$scope.inventoryUpdateMessage = "Updates to inventory: " + addedItemsMessage + removedItemsMessage

		# Get question based on inventory and number of visits
		presanitized = ""

		# Load default question
		selectedQuestion = q_data.questions[0]

		# If conditional question matches, use it instead
		if q_data.options.additionalQuestions
			selectedQuestion = inventoryService.selectQuestion(q_data, $scope.inventory, inventoryService.visitedNodes)

		if selectedQuestion
			# If the question text contains a string that doesn't pass angular's $sanitize check, it'll fail to display anything
			# Instead, parse in advance, catch the error, and warn the user that the text was nasty
			try
				# Run question text thru pre-sanitize routine because $sanitize is fickle about certain characters like >, <
				presanitized = selectedQuestion.text
				for k, v of PRESANITIZE_CHARACTERS
					presanitized = presanitized.replace k, v
				$sanitize presanitized

			catch error
				selectedQuestion.text = "*Question text removed due to malformed or dangerous HTML content*"

		unless q_data.options.asset then $scope.layout = "text-only"
		else if presanitized != "" then $scope.layout = q_data.options.asset.align
		else $scope.layout = "image-only"


		# Note: Micromarkdown is still adding a mystery newline or carriage return character to the beginning of most parsed strings (but not generated tags??)
		if presanitized.length then parsedQuestion = micromarkdown.parse(presanitized) else parsedQuestion = "No question text provided."

		# hyperlinks are automatically converted into <a href> tags, except it loads content within the iframe. To circumvent this, need to dynamically add target="_blank" attribute to all generated URLs
		parsedQuestion = addTargetToHrefs parsedQuestion

		$scope.question =
			text : parsedQuestion, # questions MUST be an array, always 1 index w/ single text property. MMD converts markdown formatting into proper markdown syntax
			layout: $scope.layout,
			type : q_data.options.type,
			id : q_data.options.id
			materiaId: q_data.id
			options: q_data.options

		$scope.answers = []

		if q_data.answers
			for i in [0..q_data.answers.length-1]
				continue if not q_data.answers[i]

				requiredItems = []
				# Format items
				if q_data.answers[i].options.requiredItems
					for r in q_data.answers[i].options.requiredItems
						do (r) ->
							# Format properties for pre-existing items without said properties
							# If minCount isn't set, set it to 1
							if r.minCount > -1
								minCount = r.minCount
							else if r.tempMinCount > -1
								minCount = r.tempMinCount
							else if r.count
								minCount = r.count
							else
								minCount = 1

							# If maxCount isn't set, set it to uncapped
							if r.maxCount > -1
								maxCount = r.maxCount
							else if r.tempMaxCount > -1
								maxCount = r.tempMaxCount
							else if r.count
								maxCount = r.count
							else
								# If maxCount isn't set, set it to minCount
								maxCount = minCount

							uncappedMax = if (r.uncappedMax isnt null) then r.uncappedMax else false

							item =
								id: r.id
								range: r.range || ""
								minCount: minCount
								maxCount: maxCount
								uncappedMax: uncappedMax

							# Format range for pre-existing items without the range property
							_assignRange item

							requiredItems.push item

				answer =
					text : q_data.answers[i].text
					link : q_data.answers[i].options.link
					index : i
					options : q_data.answers[i].options
					requiredItems: requiredItems
					hideAnswer: q_data.answers[i].options.hideAnswer || false
					hideRequiredItems: q_data.answers[i].options.hideRequiredItems || false

				if answer.requiredItems[0]
					$scope.showInventoryBtn = true

				$scope.answers.push answer

		# shuffle answer order if asked to do so
		if q_data.options.randomize then $scope.answers = _shuffleIndices $scope.answers

		$scope.q_data = q_data

		# TODO Add back in with Layout support
		# check if question has an associated asset (for now, just an image)
		# if $scope.question.type is $scope.HOTSPOT then $scope.question.layout = LAYOUT_VERT_TEXT
		if $scope.question.type is $scope.HOTSPOT then $scope.layout = "hotspot"
		if $scope.question.layout isnt "text-only"
			if $scope.question.options.asset.type is "image"
				image_url = Materia.Engine.getMediaUrl q_data.options.asset.id
				$scope.question.image = image_url
			else
				$scope.question.video = $sce.trustAsResourceUrl($scope.question.options.asset.url)

		switch q_data.options.type
			when $scope.OVER then _end() # Creator doesn't pass a value like this back yet / technically this shouldn't be called - the end call is made is _handleAnswerSelection
			when $scope.NARR, $scope.END then handleTransitional q_data
			when $scope.MC then handleMultipleChoice q_data
			when $scope.HOTSPOT then handleHotspot q_data
			when $scope.SHORTANS then handleShortAnswer q_data
			# when $scope.RESTRICTED then handleRestrictedNode q_data
			else
				handleEmptyNode() # Should hopefully only happen on preview, when empty nodes are allowed

		inventoryService.addNodeToVisited(q_data)

	$scope.dismissUpdates = () ->
		$scope.inventoryUpdate = false
		document.getElementById("inventory-update").setAttribute("inert", true)
		$scope.showNew = false

	$scope.toggleInventory = (item = null) ->
		$scope.showInventory = ! $scope.showInventory
		if ! $scope.showInventory
			document.getElementById("inventory").setAttribute("inert", "true")
			document.querySelector(".container").removeAttribute("inert")
			document.querySelector(".feedback").removeAttribute("inert")
			document.querySelector(".lightbox").removeAttribute("inert")
		else
			document.getElementById("inventory").removeAttribute("inert")
			document.querySelector(".container").setAttribute("inert", "true")
			document.querySelector(".feedback").setAttribute("inert", "true")
			document.querySelector(".lightbox").setAttribute("inert", "true")
		$scope.inventoryUpdate = false
		document.getElementById("inventory-update").setAttribute("inert", true)
		if item
			$scope.selectedItem = $scope.inventory[$scope.getItemIndex(item.id)] || null
		$scope.showNew = false

	$scope.setSelectedItem = (item) ->
		# Display item details in right toolbar
		$scope.selectedItem = item
		# Remove new label from icon
		item.new = false

	$scope.getItemIndex = (itemId) ->
		if !itemId then return false
		for i, index in $scope.itemSelection
			if i.id is itemId
				return index

	$scope.hasNotSilentItem = (items) ->
		for i in items
			if ! $scope.itemSelection[$scope.getItemIndex(i.id)].isSilent
				return true
		return false

	$scope.checkInventory = (items) ->
		return inventoryService.checkInventory $scope.inventory, items

	# Handles selection of MC answer choices and transitional buttons (narrative and end screen)
	$scope.handleAnswerSelection = (link, index) ->
		# link to -1 indicates the widget should advance to the score screen
		if link is -1 then return _end()

		$scope.selectedAnswer = $scope.q_data.answers[index].text
		selectedAnswerId = $scope.q_data.answers[index].id

		# answers[index] will be inaccurate if answers are randomized !!!
		requiredItems = getAnswerByIndex(index).requiredItems || []

		$scope.missingRequiredItems = inventoryService.checkInventory($scope.inventory, requiredItems)

		if $scope.missingRequiredItems[0]
			$scope.missingRequiredItemsAltText = $scope.missingRequiredItems.map((item) -> "#{$scope.itemSelection[$scope.getItemIndex(item.id)].name} (amount: #{requiredItems.find((el) -> el.id is item.id).range});")
			# Add range value to required items
			$scope.missingRequiredItems.map((item) -> _assignRange item)
			$scope.next = null
			return

		# Disable the hotspot label before moving on, if it's a hotspot
		if $scope.type is $scope.HOTSPOT
			$scope.hotspotLabelTarget.show = false
			$scope.hotspotLabelTarget.x = null
			$scope.hotspotLabelTarget.y = null
			_logProgress(selectedAnswerId)
		else
			# record the answer
			_logProgress()

		if $scope.q_data.answers[index].options.feedback
			$scope.feedback = $scope.q_data.answers[index].options.feedback
			$scope.next = link
		else
			manageQuestionScreen link

	# Do stuff when the user submits something in the SA answer box
	$scope.handleShortAnswerInput = ->

		response = originalResponse = $scope.response
		$scope.response = ""

		matches = []
		selectedMatch = null

		# Outer loop - loop through every answer set (index 0 is always [All Other Answers] )
		for i in [0...$scope.q_data.answers.length]

			# If it's the default, catch-all answer, then skip
			if $scope.q_data.answers[i].options.isDefault then continue

			# Loop through each match to see if it matches the recorded response
			for j in [0...$scope.q_data.answers[i].options.matches.length]

				match = $scope.q_data.answers[i].options.matches[j]

				# Remove whitespace
				match = match.trim().split('').filter((letter) -> letter.match(/\w/)).join()
				response = response.trim().split('').filter((letter) -> letter.match(/\w/)).join()

				# If matches are not character sensitive
				if (! $scope.q_data.answers[i].options.characterSensitive)
					# Remove any special characters
					# Look at alphanumeric characters only
					match = match.split('').filter((letter) -> letter.match(/\w/)).join()
					response = response.split('').filter((letter) -> letter.match(/\w/)).join()

				# If matches are not case sensitive
				if (! $scope.q_data.answers[i].options.caseSensitive)
					match = match.toLowerCase()
					response = response.toLowerCase()

				if ($scope.q_data.answers[i].options.partialMatches and response.includes(match)) or match is response then matches.push { text: match, index: i, requiresExact: !$scope.q_data.answers[i].options.partialMatches }

		# determine the selected match via most significant match criteria (if multiple matches were identified)
		if matches.length > 1 then selectedMatch = _mostSignificantMatch response, matches
		else if matches.length is 1 then selectedMatch = matches[0]

		if selectedMatch
			matchIndex = selectedMatch.index
			requiredItems = $scope.q_data.answers[matchIndex].options.requiredItems || $scope.q_data.answers[matchIndex].requiredItems
			missingItems = inventoryService.checkInventory($scope.inventory, requiredItems)

			requiredItems = $scope.q_data.answers[matchIndex].options.requiredItems || $scope.q_data.answers[matchIndex].requiredItems
			$scope.missingRequiredItems = inventoryService.checkInventory($scope.inventory, requiredItems)

			if $scope.missingRequiredItems[0]
				$scope.missingRequiredItemsAltText = missingItems.map((item) -> "#{$scope.itemSelection[$scope.getItemIndex(item.id)].name} (amount: #{requiredItems.find((el) -> el.id is item.id).range});")
				# Add range value to required items
				$scope.missingRequiredItems.map((item) -> _assignRange item)
				$scope.next = null
				return

			link = ~~$scope.q_data.answers[matchIndex].options.link # is parsing required?

			$scope.selectedAnswer = originalResponse
			_logProgress()

			if $scope.q_data.answers[matchIndex].options and $scope.q_data.answers[matchIndex].options.feedback
				$scope.feedback = $scope.q_data.answers[matchIndex].options.feedback
				$scope.next = link
			else
				manageQuestionScreen link

			return true

		# Fallback in case the user response doesn't match anything. Have to match the link associated with [All Other Answers]
		for answer in $scope.q_data.answers
			if answer.options.isDefault

				$scope.selectedAnswer = originalResponse
				_logProgress() # Log the response

				link = ~~answer.options.link
				if answer.options.feedback
					$scope.feedback = answer.options.feedback
					$scope.next = link
				else
					manageQuestionScreen link

				return false

	$scope.closeFeedback = () ->
		if $scope.feedback.length > 0 # prevent multiple calls to manageQuestionScreen from firing due to the scope cycle not updating fast enough
			$scope.feedback = ""
			if $scope.next
				manageQuestionScreen $scope.next

	$scope.closeTutorial = () ->
		$scope.showTutorial = false
		manageQuestionScreen($scope.startID)

	$scope.closeMissingRequiredItems = () ->
		if $scope.missingRequiredItems.length > 0
			$scope.missingRequiredItems = []
			$scope.missingRequiredItemsAltText = ""

	getAnswerByIndex = (index) ->
		for answer in $scope.answers
			if answer.index == index then return answer
		return null

	handleMultipleChoice = (q_data) ->
		$scope.type = $scope.MC

	handleHotspot = (q_data) ->
		$scope.type = $scope.HOTSPOT
		$scope.question.layout = 1

		$scope.question.options.hotspotColor = 7772386 if not $scope.question.options.hotspotColor
		$scope.question.options.hotspotColor = '#' + ('000000' + $scope.question.options.hotspotColor.toString(16)).substr(-6)

		img = new Image()
		img.src = $scope.question.image

		img.onload = ->
			# if it's an old QSet, the hotspot has to be scaled once the image is loaded
			# The old hotspot coordinate system scales the hotspot points based on original image size, so can't do this step earlier
			if $scope.q_data.options.legacyScaleMode
				legacyQsetSrv.handleLegacyScale $scope.answers, img
				$scope.$apply()

				# This doesn't change the saved QSet, but it prevents the scaling from being applied twice if you come back to this node.
				delete $scope.q_data.options.legacyScaleMode

	handleShortAnswer = (q_data) ->
		$scope.type = $scope.SHORTANS
		$scope.response = ""

	# Transitional questions are the ones that don't require answers - i.e., narrative and end node
	handleTransitional = (q_data) ->
		# Set the link based on the node type - for end screens, the link is -1 (score screen) and submit the final score
		link = null
		if $scope.question.type is $scope.END
			link = -1
			Materia.Score.submitFinalScoreFromClient q_data.options.id, $scope.question.text, q_data.options.finalScore
		else
			link = q_data.answers[0].options.link

		$scope.link = link
		$scope.type = $scope.TRANS

	handleEmptyNode = (q_data) ->
		$scope.type = $scope.TRANS
		$scope.layout = "text-only"
		$scope.question.text = "[Blank destination: click Continue to end the widget preview.]"
		$scope.link = -1
		Materia.Score.submitFinalScoreFromClient null, "Blank Destination! Be sure to edit or remove this node before publishing.", 100

	# handleRestrictedNode = () ->
	# 	$scope.type = $scope.RESTRICTED
	# 	$scope.layout = "text-only"
	# 	itemArray = item.name for item in $scope.question.requiredItems
	# 	$scope.question.text = "[Destination requires item(s): [#{itemArray.toString(', ')}]]"
	# 	$scope.link = $scope.question.options.parentId

	_mostSignificantMatch = (response, matches) ->
		mostSignificantMatch = { text: '' }
		for option in matches
			# exact match against an answer that requires exact matches takes top priority
			if option.requiresExact then return mostSignificantMatch = option
			# exact match against an answer that allows partial matches
			else if option.text == response then return mostSignificantMatch = option
			# fuzzy match of highest complexity (longest string length)
			else if option.text.length > mostSignificantMatch.text.length then mostSignificantMatch = option
		return mostSignificantMatch

	# Submit the user's response to the logs
	_logProgress = (answerId = undefined) ->
		if answerId != undefined then Materia.Score.submitQuestionForScoring $scope.question.materiaId, $scope.selectedAnswer, answerId
		else Materia.Score.submitQuestionForScoring $scope.question.materiaId, $scope.selectedAnswer

	_end = ->
		if $scope.scoringDisabled
			Materia.Engine.end no

			$scope.question =
				type: 'over'
				text: if $scope.customInternalScoreMessage.length then $scope.customInternalScoreMessage else 'You have completed this experience and your progress has been recorded. You can close or navigate away from this page.'
				layout: 'text-only'
				id: -1

			$scope.layout = $scope.question.layout
		else
			Materia.Engine.end yes

	# Kinda hackish, since both autoTextScale and dynamicScale directives update the "style" attribute,
	# need to combine updated properties from both so they don't overwrite each other.
	$scope.formatQuestionStyles = ->
		return "font-size:" + $scope.questionFormat.fontSize + "px;"

	_qsetHasInventoryItems = (qset) ->
		for n in [0...$scope.qset.items.length]
			if $scope.qset.items[n].options.items and $scope.qset.items[n].options.items[0] then return true
		false

	_assignRange = (item) ->
		if item.uncappedMax and item.minCount is 0
			item.range = "any amount"
		else if item.minCount is 0 and item.maxCount is 0
			item.range = "none"
		else if item.uncappedMax
			item.range = "at least #{item.minCount}"
		else if item.minCount is 0
			item.range = "no more than #{item.maxCount}"
		else if item.minCount is item.maxCount
			item.range = "#{item.minCount}"
		else
			item.range = "#{item.minCount} to #{item.maxCount}"

	# Small script that inserts " target="_blank"  " into a hrefs, preventing hyperlinks from displaying within the iframe.
	addTargetToHrefs = (string) ->

		pattern = /(?:<a\ [A-Za-z0-9\_\-\=\"\ \:\/\.\#\?\$]*)/g
		newString = string

		while (match = pattern.exec newString) isnt null
			start = match['index']
			pre = newString.substring 0, start
			post = newString.substring start + match[0].length

			newString = pre + match[0] + " target=\"_blank\" rel=\"noopener\"" + post

		newString

	# Shuffles an array using the Fisher-Yates sorting algorithm. Used to randomize answer arrays.
	_shuffleIndices = (a) ->
		i = a.length
		while --i > 0
			j = ~~(Math.random() * (i + 1))
			t = a[j]
			a[j] = a[i]
			a[i] = t
		a

	# light this candle
	Materia.Engine.start(materiaCallbacks)
]


## DIRECTIVES ##
.directive "ngEnter", [() ->
	return (scope, element, attrs) ->
		element.bind("keypress", (event) ->
			if(event.which == 13 or event.which == 10)
				event.target.blur()
				event.preventDefault()
				scope.$apply ->
					scope.$eval(attrs.ngEnter)
		)
]

# Font will progressively step down from 22px to 12px depending on question length after a threshold is reached
.directive "autoTextScale", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		scaleFactor = 100
		scaleThreshold = 200

		style = ""

		$scope.$watch "question", (newVal, oldVal) ->

			if newVal

				text = $element.text()

				if $scope.layout is "right" or $scope.layout is "left"
					scaleFactor = 20
					scaleThreshold = 140

				else if $scope.layout is "top" or $scope.layout is "bottom"
					scaleFactor = 15
					scaleThreshold = 140

				else if $scope.layout is "hotspot"
					scaleFactor = 10
					scaleThreshold = 100

				else
					scaleFactor = 100
					scaleThreshold = 200

				$scope.questionFormat.fontSize = 22 # default font size

				if text.length > scaleThreshold
					diff = (text.length - scaleThreshold) / scaleFactor
					$scope.questionFormat.fontSize -= diff

					if $scope.questionFormat.fontSize < 14 then $scope.questionFormat.fontSize = 14

				$attrs.$set "style", $scope.formatQuestionStyles()
]

# Scales the height of the question box dynamically based on the height of the answer box
# Ensures the negative space is effectively filled up with question text
# Only used for MC, since MC is the only node type with variable answer container heights
.directive "dynamicScale", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		minHeight = 220
		maxHeight = if $scope.hidePlayerTitle then 480 else 438

		minAnswerHeight = 62 # Minimum height of the answer container, subtracted from the answersHeight so we only know the scaled amount
		maxAnswerHeight = 250 # Max height of answer container, used to calculate diff

		style = ""

		$scope.$watch "question", (newVal, oldVal) ->
			# answer div:
				# min: 94
				# max: 250

			# question div:
				# min: 220
				# max: 400

			answersHeight = document.getElementsByClassName("answers")[0].getBoundingClientRect().height - minAnswerHeight

			diff = maxAnswerHeight - answersHeight

			if (diff + minHeight) < maxHeight then $scope.questionFormat.height = diff + minHeight
			else $scope.questionFormat.height = maxHeight

			$attrs.$set "style", $scope.formatQuestionStyles()
]

# Images in the player are subject to a number of constraints that makes scaling them logically complicated
# Scaling is dependent on width of accompanying text, available height (constrained by header & answer container), and horiz/vertical layout
# Logic must be applied AFTER image has loaded in order to properly query width and height
.directive "dynamicMediaScale", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->


		calcMediaSize = (width, height) ->
			# Get width of text container (if it has any text)
			unless document.getElementsByClassName("text")[0] then textWidth = 0
			else textWidth = document.getElementsByClassName("text")[0].getBoundingClientRect().width

			# Get height of answers container (min height is 62, so reduce by that value)
			answersHeight = document.getElementsByClassName("answers")[0].getBoundingClientRect().height - 62

			# Permutations based on whether or not the text/asset is aligned vertically
			if $scope.layout is "top" or $scope.layout is "bottom" then maxWidth = textWidth
			else maxWidth = containerWidth - textWidth - 160

			# Adjust height based on whether the title header is taking up space
			if $scope.hideTitle then maxHeight = maxHeightSansTitle - answersHeight
			else maxHeight = maxHeightWithTitle - answersHeight

			# Final adjustment to height to compensate for space being used by text in vertical orientations
			if $scope.layout is "top" or $scope.layout is "bottom" then maxHeight -= document.getElementsByClassName("text")[0].getBoundingClientRect().height + 20

			# Determine scale ratio based on dimensions of the image asset
			ratio = Math.min(maxWidth/width, maxHeight/height)

			scaledWidth = if ($scope.layout is "image-only") or ((width * ratio) < (containerWidth / 2)) then (width * ratio) else (containerWidth * 2 / 5)
			scaledHeight = if ($scope.question.options.asset.type is "video") then ((height * ratio) + "px") else "auto"

			# Apply scaling
			$attrs.$set "style", "width:"+scaledWidth+"px;height:"+scaledHeight+";"

		# Constants
		containerWidth = 800

		maxHeightWithTitle = 380
		maxHeightSansTitle = 440

		$scope.$watch "question", (newVal, oldVal) ->

			if newVal.image
				# Temporarily make image invisible while it loads (so it's not all wonky)
				$attrs.$set "style", "display:none;"

				img = new Image()
				img.src = newVal.image

				img.onload = ->
					calcMediaSize(img.width, img.height)
			else
				calcMediaSize(1280, 720)
]

# Handles the visibility of individual hotspots
.directive "visibilityManager", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "question", (newVal, oldVal) ->

			if $scope.question.type is $scope.HOTSPOT
				$element.removeAttr "style"

				switch $scope.q_data.options.visibility
					when "mouseover"
						style = "opacity: 0"
						$attrs.$set "style", style

						$element.bind "mouseover", (evt) ->
							$element.removeAttr "style"
							$element.unbind "mouseover"

					when "never"
						style = "opacity: 0"
						$attrs.$set "style", style
]

.directive "labelManager", ['$timeout', 'inventoryService', ($timeout, inventoryService) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# reference to hotspot div element (required for proper X/Y offset)
		hotspotDivReference = angular.element($element).parent().parent()
		# reference to label element (need to find width for proper X offset)
		hotspotLabelReference = angular.element(document.getElementById("hotspot-label"))

		$scope.onHotspotHover = (answer, evt) ->

			if answer.text then $scope.hotspotLabelTarget.text = answer.text
			else return false

			$scope.hotspotLabelTarget.ariaLabel = answer.text + (if inventoryService.checkInventory($scope.inventory, answer.requiredItems).length > 0 then ' Cannot select. ' else ' ')
			requiredItemString = answer.requiredItems.map((item) -> $scope.itemSelection[$scope.getItemIndex(item.id)].name + ' (amount: ' + item.range + ')').join(', ')
			$scope.hotspotLabelTarget.ariaLabel += (if (answer.requiredItems && answer.requiredItems.length > 0) then ('Required Items: ' + requiredItemString) else '')

			container = document.getElementById "body"

			svgBounds = angular.element($element)[0].getBoundingClientRect()

			# Position the hotspot label just below the hotspot
			$scope.hotspotLabelTarget.x = (svgBounds.left + (svgBounds.width/2)) - hotspotDivReference[0].getBoundingClientRect().left
			$scope.hotspotLabelTarget.y = (svgBounds.bottom + 5) - hotspotDivReference[0].getBoundingClientRect().top

			# Need a timeout so the text is rendered within the label
			# Once its rendered, we offset the X position by half the width so its centered
			# We also check to see if label is clipped by lower edge of iframe, if so move it so it's above the hotspot
			$timeout ->
				labelWidthOffset = hotspotLabelReference[0].getBoundingClientRect().width /2
				$scope.hotspotLabelTarget.x -= labelWidthOffset

				if hotspotLabelReference[0].getBoundingClientRect().bottom > container.offsetHeight
					$scope.hotspotLabelTarget.y = (svgBounds.top + 5) - hotspotLabelReference[0].getBoundingClientRect().height - hotspotDivReference[0].getBoundingClientRect().top

				$scope.hotspotLabelTarget.show = true

		$scope.onHotspotHoverOut = (evt) ->
			$scope.hotspotLabelTarget.show = false
			$scope.hotspotLabelTarget.x = null
			$scope.hotspotLabelTarget.y = null
]

.directive "focusManager", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "question", (newVal, oldVal) ->

			# Focuses on the text after each answer has been given so screen reader users
			# don't have to go back in the order of the widget
			if newVal != undefined then $element[0].focus()
]

.directive "tutorialFocusManager", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# Auto-focus feedback close button when visible
		$scope.$watch "showTutorial", (newVal, oldVal) ->
			if newVal then $element[0].focus()
]

.directive "feedbackFocusManager", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# Auto-focus feedback close button when visible
		$scope.$watch "feedback", (newVal, oldVal) ->
			if newVal and newVal.length > 0 then $element[0].focus()
]

.directive "lightboxFocusManager", ['$timeout', ($timeout) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# Auto-focus lightbox close button when visible
		$scope.$watch "lightboxTarget", (newVal, oldVal) ->
			$timeout -> $element[0].focus()
]
