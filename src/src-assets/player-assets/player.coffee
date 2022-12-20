Adventure = angular.module('Adventure', ['ngAria', 'ngSanitize'])

## CONTROLLER ##
Adventure.controller 'AdventureController', ['$scope','$rootScope','legacyQsetSrv','$sanitize', '$sce', '$timeout', ($scope, $rootScope, legacyQsetSrv, $sanitize, $sce, $timeout) ->

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
	$scope.showInventoryBtn = false
	$scope.scoringDisabled = false
	$scope.customInternalScoreMessage = "" # custom "internal score screen" message, if blank then use default
	$scope.inventory = []
	$scope.itemSelection = []

	materiaCallbacks =
		start: (instance, qset, version = '1') ->
			#Convert an old qset prior to running the widget
			if parseInt(version) is 1 then qset = JSON.parse legacyQsetSrv.convertOldQset qset

			$scope.$apply ->
				$scope.title = instance.name
				$scope.qset = qset
				$scope.itemSelection = qset.options.inventoryItems
				$scope.startID = qset.items[0].options.id

				if qset.options.startID isnt 0
					$scope.startID = qset.options.startID

				manageQuestionScreen($scope.startID)

				if qset.options.hidePlayerTitle then $scope.hideTitle = qset.options.hidePlayerTitle
				else $scope.hideTitle = false # default is to display title

				if qset.options.scoreMode and qset.options.scoreMode is "Non-Scoring"
					$scope.scoringDisabled = true
					if qset.options.internalScoreMessage then $scope.customInternalScoreMessage = qset.options.internalScoreMessage

		manualResize: true

	$scope.questionFormat =
		fontSize: 22
		height: 220

	# Lightbox
	$scope.lightboxTarget = -1

	$scope.setLightboxTarget = (val) ->
		$scope.lightboxTarget = val

	$scope.lightboxZoom = 0

	$scope.setLightboxZoom = (val) ->
		$scope.lightboxZoom = val

	$scope.visitedNodes = []

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

		unless q_data.options.asset then $scope.layout = "text-only"
		else if q_data.questions[0].text != "" then $scope.layout = q_data.options.asset.align
		else $scope.layout = "image-only"

		# If the question text contains a string that doesn't pass angular's $sanitize check, it'll fail to display anything
		# Instead, parse in advance, catch the error, and warn the user that the text was nasty
		try
			# Run question text thru pre-sanitize routine because $sanitize is fickle about certain characters like >, <
			presanitized = q_data.questions[0].text
			for k, v of PRESANITIZE_CHARACTERS
				presanitized = presanitized.replace k, v
			$sanitize presanitized

		catch error
			q_data.questions[0].text = "*Question text removed due to malformed or dangerous HTML content*"

		# Note: Micromarkdown is still adding a mystery newline or carriage return character to the beginning of most parsed strings (but not generated tags??)
		if presanitized.length then parsedQuestion = micromarkdown.parse(presanitized) else parsedQuestion = ""

		# hyperlinks are automatically converted into <a href> tags, except it loads content within the iframe. To circumvent this, need to dynamically add target="_blank" attribute to all generated URLs
		parsedQuestion = addTargetToHrefs parsedQuestion

		$scope.question =
			text : parsedQuestion, # questions MUST be an array, always 1 index w/ single text property. MMD converts markdown formatting into proper markdown syntax
			layout: $scope.layout,
			type : q_data.options.type,
			id : q_data.options.id
			materiaId: q_data.id
			options: q_data.options

		# Remove new item alerts
		for i in $scope.inventory
			i.new = false

		$scope.addedItems = []
		$scope.removedItems = []
		$scope.inventoryUpdate = false
		$scope.questionItems = []

		# Add items to player's inventory
		if $scope.question.options.items and $scope.question.options.items[0]

			$scope.showInventoryBtn = true
			
			# Format items
			if $scope.question.options.items
				for q_i in $scope.question.options.items
					do (q_i) ->
						item =
							id: q_i.id
							count: q_i.count || 1
							takeAll: q_i.takeAll || false
							firstVisitOnly: q_i.firstVisitOnly || false
						$scope.questionItems.push item

			for q_i in $scope.questionItems
				do (q_i) ->
					hasItem = false

					# Check if item is first visit only and player has visited this node before
					if ($scope.visitedNodes.some((n) => n is $scope.question.id) and q_i.firstVisitOnly)
						# Move to next item
					else
						# Inventory update
						if q_i.count < 0 or q_i.takeAll
							# Only show removed items if player has the item in inventory
							if $scope.inventory.some((i) => i.id is q_i.id)
								# Can't take more than what is in player inventory
								if Math.abs(q_i.count) > i.count or q_i.takeAll
									q_i.count = -1 * i.count
								if ! $scope.itemSelection[$scope.getItemIndex(q_i)].isSilent
									$scope.removedItems.push(q_i)
						else
							if ! $scope.itemSelection[$scope.getItemIndex(q_i)].isSilent
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
			if ($scope.removedItems[0] || $scope.addedItems[0])
				$scope.inventoryUpdate = true
				if $scope.addedItems[0]
					$scope.showNew = true


		$scope.answers = []

		if q_data.answers
			for i in [0..q_data.answers.length-1]
				continue if not q_data.answers[i]

				requiredItems = []
				# Format items
				if q_data.answers[i].options.requiredItems
					for r in q_data.answers[i].options.requiredItems
						do (r) ->
							console.log(r)
							# Format properties for pre-existing items without said properties
							# If minCount isn't set, set it to 1
							minCount = r.minCount or r.tempMinCount or r.count or 1
							# Past versions had maxCount set to -1 for no minimum values
							if minCount < 1 then minCount = 1

							# If maxCount isn't set, set it to uncapped
							maxCount = r.maxCount or r.tempMaxCount or 1
							# Past versions had maxCount set to -1 for uncapped values
							if maxCount < 1 then maxCount = minCount

							uncappedMax = if (r.uncappedMax isnt null) then r.uncappedMax else false

							noMin = if (r.noMin isnt null) then r.noMin else false

							item =
								id: r.id
								range: r.range || ""
								minCount: minCount
								maxCount: maxCount
								uncappedMax: uncappedMax
								noMin: noMin
							
							# Format range for pre-existing items without the range property
							if item.range is ""
								if item.uncappedMax and item.noMin
									item.range = "any amount"
								else if item.uncappedMax
									item.range = "at least #{item.minCount}"
								else if item.noMin
									item.range = "no more than #{item.maxCount}"
								else
									item.range = "#{item.minCount} - #{item.maxCount}"
							
							console.log(item)
							requiredItems.push item

				answer =
					text : q_data.answers[i].text
					link : q_data.answers[i].options.link
					index : i
					options : q_data.answers[i].options
					requiredItems: requiredItems
					hideAnswer: q_data.answers[i].options.hideAnswer || false
					# hideRequiredItems: q_data.answers[i].options.hideRequiredItems || false

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

		$scope.visitedNodes.push(q_data.options.id)

	$scope.toggleInventory = (item = null) ->
		$scope.showInventory = ! $scope.showInventory
		$scope.inventoryUpdate = false
		$scope.selectedItem = $scope.inventory[$scope.getItemIndex(item)] || null
		$scope.showNew = false

	$scope.setSelectedItem = (item) ->
		# Display item details in right toolbar
		$scope.selectedItem = item
		# Remove new label from icon
		item.new = false

	$scope.getItemIndex = (item) ->
		if !item then return false
		for i, index in $scope.itemSelection
			if i.id is item.id
				return index

	$scope.hasNotSilentItem = (items) ->
		for i in items
			if ! $scope.itemSelection[$scope.getItemIndex(i)].isSilent
				return true
		return false

	# Checks to see if player inventory contains all required items
	# Returns array of missing items
	$scope.checkInventory = (requiredItems) ->
		missingItems = []
		angular.forEach requiredItems, (item) ->
			hasItemInInventory = false
			hasRequiredItem = $scope.inventory.some (playerItem) ->
				if playerItem.id is item.id 
					hasItemInInventory = true
					# Check if player has more than the min
					if playerItem.count >= item.minCount or item.noMin
						# Check if player has less than the max
						if playerItem.count <= item.maxCount or item.uncappedMax
							return true
					return false
			# Check if player doesn't have item but there is no minimum
			if ! hasItemInInventory and item.noMin
				hasRequiredItem = true
			if ! hasRequiredItem
				missingItems.push(item.id)
		return missingItems

	# Handles selection of MC answer choices and transitional buttons (narrative and end screen)
	$scope.handleAnswerSelection = (link, index) ->
		# link to -1 indicates the widget should advance to the score screen
		if link is -1 then return _end()

		$scope.selectedAnswer = $scope.q_data.answers[index].text

		missingItems = $scope.checkInventory($scope.answers[index].requiredItems)

		if missingItems[0]
			# string = missingItems.map((item) ->
			# 	range = ""
			# 	if item.minCount < item.maxCount
			# 		range = item.minCount + "-" + item.maxCount
			# 	else
			# 		range = item.minCount
			# 	" #{$scope.itemSelection[$scope.getItemIndex(item)].name} (amount: #{range})"
			# )
			# $scope.feedback = "Requires the items: #{string}"
			$scope.next = null
			return

		# Disable the hotspot label before moving on, if it's a hotspot
		if $scope.type is $scope.HOTSPOT
			$scope.hotspotLabelTarget.show = false
			$scope.hotspotLabelTarget.x = null
			$scope.hotspotLabelTarget.y = null

		# record the answer
		_logProgress()

		if $scope.q_data.answers[index].options.feedback
			$scope.feedback = $scope.q_data.answers[index].options.feedback
			$scope.next = link
		else
			manageQuestionScreen link

	# Do stuff when the user submits something in the SA answer box
	$scope.handleShortAnswerInput = ->

		response = $scope.response
		$scope.response = ""

		# Outer loop - loop through every answer set (index 0 is always [All Other Answers] )
		for i in [0...$scope.q_data.answers.length]

			# If it's the default, catch-all answer, then skip
			if $scope.q_data.answers[i].options.isDefault then continue

			# Loop through each match to see if it matches the recorded response
			for j in [0...$scope.q_data.answers[i].options.matches.length]


				# TODO make matching algo more robust
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

				if match is response

					missingItems = $scope.checkInventory($scope.answers.requiredItems)

					if missingItems[0]
						# range = ""
						# if item.minCount < item.maxCount
						# 	range = item.minCount + "-" + item.maxCount
						# else
						# 	range = item.minCount
						# string = missingItems.map((item) -> "#{$scope.itemSelection[$scope.getItemIndex(item)].name} (amount: #{range});")
						# $scope.feedback = "Requires the items: #{string}"
						$scope.next = null
						return

					link = ~~$scope.q_data.answers[i].options.link # is parsing required?

					$scope.selectedAnswer = $scope.q_data.answers[i].options.matches[j]
					_logProgress()

					if $scope.q_data.answers[i].options and $scope.q_data.answers[i].options.feedback
						$scope.feedback = $scope.q_data.answers[i].options.feedback
						$scope.next = link
					else
						manageQuestionScreen link

					return true

		# Fallback in case the user response doesn't match anything. Have to match the link associated with [All Other Answers]
		for answer in $scope.q_data.answers
			if answer.options.isDefault

				$scope.selectedAnswer = response
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
			Materia.Score.submitFinalScoreFromClient q_data.id, q_data.questions[0].text, q_data.options.finalScore
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

	# Submit the user's response to the logs
	_logProgress = ->

		if $scope.selectedAnswer isnt null # TODO is this check required??
			Materia.Score.submitQuestionForScoring $scope.question.materiaId, $scope.selectedAnswer

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
	# If the node isn't MC, just return fontSize, height isn't used
	$scope.formatQuestionStyles = ->

		if $scope.question.type is $scope.MC
			return "font-size:" + $scope.questionFormat.fontSize + "px; height:" + $scope.questionFormat.height + "px;"
		else return "font-size:" + $scope.questionFormat.fontSize + "px;"

	Materia.Engine.start(materiaCallbacks)

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
]


## DIRECTIVES ##
Adventure.directive "ngEnter", [() ->
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
Adventure.directive "autoTextScale", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		scaleFactor = 100
		scaleThreshold = 200

		style = ""

		$scope.$watch "question", (newVal, oldVal) ->

			if newVal

				text = $element.text()

				if angular.element($element[0]).hasClass("right") or angular.element($element).hasClass("left")
					scaleFactor = 25
					scaleThreshold = 180

				else if angular.element($element[0]).hasClass("top") or angular.element($element).hasClass("bottom")
					scaleFactor = 10
					scaleThreshold = 140

				else
					scaleFactor = 100
					scaleThreshold = 200

				$scope.questionFormat.fontSize = 22 # default font size

				if text.length > scaleThreshold
					diff = (text.length - scaleThreshold) / scaleFactor
					$scope.questionFormat.fontSize -= diff

					if $scope.questionFormat.fontSize < 12 then $scope.questionFormat.fontSize = 12

				$attrs.$set "style", $scope.formatQuestionStyles()
]

# Scales the height of the question box dynamically based on the height of the answer box
# Ensures the negative space is effectively filled up with question text
# Only used for MC, since MC is the only node type with variable answer container heights
Adventure.directive "dynamicScale", [() ->
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
Adventure.directive "dynamicMediaScale", [() ->
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
Adventure.directive "visibilityManager", [() ->
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

Adventure.directive "labelManager", ['$timeout', ($timeout) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# reference to hotspot div element (required for proper X/Y offset)
		hotspotDivReference = angular.element($element).parent().parent()
		# reference to label element (need to find width for proper X offset)
		hotspotLabelReference = angular.element(document.getElementById("hotspot-label"))

		$scope.onHotspotHover = (answer, evt) ->

			if answer.text then $scope.hotspotLabelTarget.text = answer.text
			else return false

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

Adventure.directive "focusManager", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "question", (newVal, oldVal) ->

			# Focuses on the text after each answer has been given so screen reader users
			# don't have to go back in the order of the widget
			$element[0].focus()
]

Adventure.directive "feedbackFocusManager", [() ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# Auto-focus feedback close button when visible
		$scope.$watch "feedback", (newVal, oldVal) ->
			if newVal and newVal.length > 0 then $element[0].focus()
]

Adventure.directive "lightboxFocusManager", ['$timeout', ($timeout) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# Auto-focus lightbox close button when visible
		$scope.$watch "lightboxTarget", (newVal, oldVal) ->
			$timeout -> $element[0].focus()
]
