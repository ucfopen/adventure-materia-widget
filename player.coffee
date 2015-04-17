AdventureApp = angular.module('AdventureApp', [])

AdventureApp.controller 'AdventureController', ['$scope', ($scope) ->

	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.TRANS = "transitional"
	$scope.NARR = "narrative" # May not be required
	$scope.END = "end" # May not be required
	$scope.OVER = "over" # the imaginary node after end nodes, representing the end of the widget

	# TODO Are these really required?
	PADDING_LEFT = 20
	PADDING_TOP = 15
	CONTAINER_WIDTH = 730
	CONTAINER_HEGIHT = 650

	$scope.title = ""
	$scope.qset = null

	$scope.engine =
		start: (instance, qset, version = '1') ->
			$scope.$apply ->
				$scope.title = instance.name
				$scope.qset = qset
				manageQuestionScreen(qset.items[0].options.id)
		manualResize: true

	# Update the screen depending on the question type (narrative, mc, short answer, hotspot, etc)
	manageQuestionScreen = (questionId) ->

		# Acquire question data based on question id
		for n in [0...$scope.qset.items.length]
			if $scope.qset.items[n].options.id is questionId
				q_data = $scope.qset.items[n]

		unless q_data.options.asset then $scope.layout = "text-only"
		else $scope.layout = q_data.options.asset.align

		$scope.question =
			text : q_data.question, # questions is no longer an array of objects, flattened to single property
			layout: $scope.layout,
			type : q_data.options.type,
			id : q_data.options.id
			options: q_data.options

		$scope.answers = []

		if q_data.answers
			for i in [0..q_data.answers.length-1]
				continue if not q_data.answers[i]

				answer =
					text : q_data.answers[i].text
					link : q_data.answers[i].options.link
					index : i
					options : q_data.answers[i].options
				$scope.answers.push answer

		$scope.q_data = q_data

		# TODO Add back in with Layout support
		# check if question has an associated asset (for now, just an image)
		# if $scope.question.type is $scope.HOTSPOT then $scope.question.layout = LAYOUT_VERT_TEXT
		if $scope.question.type is $scope.HOTSPOT then $scope.question.layout = "bottom"
		if $scope.question.layout isnt "text-only"
			image_url = Materia.Engine.getImageAssetUrl q_data.options.asset.id
			$scope.question.image = image_url

		switch q_data.options.type
			when $scope.OVER then _end() # Creator doesn't pass a value like this back yet / technically this shouldn't be called - the end call is made is _handleAnswerSelection
			when $scope.NARR, $scope.END then handleTransitional q_data
			when $scope.MC then handleMultipleChoice q_data
			when $scope.HOTSPOT then handleHotspot q_data
			when $scope.SHORTANS then handleShortAnswer q_data
			else
				handleEmptyNode() # Should hopefully only happen on preview, when empty nodes are allowed

	# Handles selection of MC answer choices and transitional buttons (narrative and end screen)
	$scope.handleAnswerSelection = (link, index) ->
		# link to -1 indicates the widget should advance to the score screen
		if link is -1 then return _end()

		$scope.selectedAnswer = $scope.q_data.answers[index].text

		# record the answer
		_logProgress()

		if $scope.q_data.answers[index].options.feedback
			$scope.feedback = $scope.q_data.answers[index].options.feedback
			$scope.next = link
		else
			manageQuestionScreen link

	# Do stuff when the user submits something in the SA answer box
	$scope.handleShortAnswerInput = ->

		answer = $scope.response.toLowerCase()
		$scope.response = ""

		# Outer loop - loop through every answer set (index 0 is always [All Other Answers] )
		for i in [0...$scope.q_data.answers.length]

			# If it's the default, catch-all answer, then skip
			if $scope.q_data.answers[i].options.isDefault then continue

			# Loop through each match to see if it matches the recorded response
			for j in [0...$scope.q_data.answers[i].options.matches.length]

				# TODO make matching algo more robust
				if $scope.q_data.answers[i].options.matches[j].toLowerCase().trim() is answer

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

				$scope.selectedAnswer = $scope.q_data.answers[0]
				_logProgress() # Log the response

				link = ~~answer.options.link
				if answer.options.feedback
					$scope.feedback = answer.options.feedback
					$scope.next = link
				else
					manageQuestionScreen link

				return false

	$scope.closeFeedback = ->
		$scope.feedback = ""
		manageQuestionScreen $scope.next

	handleMultipleChoice = (q_data) ->
		$scope.type = $scope.MC

	handleHotspot = (q_data) ->
		$scope.type = $scope.HOTSPOT
		$scope.question.layout = 1

		# TODO Update so each individual hotspot receives a color
		$scope.question.options.hotspotColor = 7772386 if not $scope.question.options.hotspotColor
		$scope.question.options.hotspotColor = '#' + ('000000' + $scope.question.options.hotspotColor.toString(16)).substr(-6)

		console.log $scope.question.image

		img = new Image()
		img.src = $scope.question.image
		img.onload = ->

			for answer in $scope.answers

				if answer.options.svg.type is "polygon"
					coords = answer.options.svg.points.split(" ")[0].split(",")

					console.log coords
					answer.balloonleft = coords[0]
					answer.balloontop = coords[1]
				else
					answer.balloonleft = answer.options.svg.x
					answer.balloontop = answer.options.svg.y

			$scope.$apply()

	handleShortAnswer = (q_data) ->
		$scope.type = $scope.SHORTANS
		$scope.response = ""

	# Transitional questions are the ones that don't require answers - i.e., narrative and end node
	handleTransitional = (q_data) ->
		# Set the link based on the node type - for end screens, the link is -1 (score screen) and submit the final score
		link = null
		if $scope.question.type is $scope.END
			link = -1
			Materia.Score.submitFinalScoreFromClient q_data.id, $scope.question.text, q_data.options.finalScore
		else
			link = q_data.answers[0].options.link

		$scope.link = link
		$scope.type = $scope.TRANS

	handleEmptyNode = -> null

	# Submit the user's response to the logs
	_logProgress = ->

		if $scope.selectedAnswer isnt null # TODO is this check required??
			Materia.Score.submitQuestionForScoring $scope.question.id, $scope.selectedAnswer

		# # if answer_index is -1 then answer_text = "N/A" else answer_text = question.answers[answer_index].text
		# answer_text = null if answer_text == "[No Answer]"

	_end = ->
		Materia.Engine.end yes

	Materia.Engine.start($scope.engine)
]

AdventureApp.directive('ngEnter', ->
	return (scope, element, attrs) ->
		element.bind("keypress", (event) ->
			if(event.which == 13 or event.which == 10)
				event.target.blur()
				event.preventDefault()
				scope.$apply ->
					scope.$eval(attrs.ngEnter)
		)
)

