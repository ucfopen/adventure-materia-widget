AdventureApp = angular.module('AdventureApp', [])

AdventureApp.controller 'AdventureController', ['$scope', ($scope) ->
	LAYOUT_IMAGE_ONLY = 0	# Layout that contains only an image
	LAYOUT_TEXT_ONLY = 1 	# Layout that contains only text
	LAYOUT_HORIZ_TEXT = 2 	# Horizontal layout that contains text and then an image
	LAYOUT_HORIZ_IMAGE = 3 	# Horizontal layout that contains an image and then text
	LAYOUT_VERT_TEXT = 4 	# Vertical layout that contains text and then an image
	LAYOUT_VERT_IMAGE = 5 	# Vertical layout that contains an image and then text

	PADDING_LEFT = 0
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
				manageQuestionScreen(qset.items[0].items[0])
		manualResize: true

	# Update the screen depending on the question type (narrative, mc, short answer, hotspot, etc)
	manageQuestionScreen = (q_data) ->

		$scope.question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		$scope.answers = []

		if q_data.answers
			for i in [0..q_data.answers.length-1]
				answer =
					text : q_data.answers[i].text
					link : q_data.answers[i].options.link
					index : i
					options : q_data.answers[i].options
				$scope.answers.push answer

		$scope.q_data = q_data

		# check if question has an associated asset (for now, just an image)
		if $scope.question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl q_data.options.asset.id
			$scope.question.image = image_url

		switch q_data.options.type
			when -1 then _end() # technically this shouldn't be called - the end call is made is _handleAnswerSelection
			when 1, 5 then handleTransitional(q_data)
			when 2 then handleMultipleChoice(q_data)
			when 3 then handleHotspot(q_data)
			when 4 then handleShortAnswer(q_data)
			else
				handleEmptyNode # Should hopefully only happen on preview, when empty nodes are allowed

	# Handles selection of MC answer choices and transitional buttons (narrative and end screen)
	$scope.handleAnswerSelection = (link, index) ->
		# link to -1 indicates the widget should advance to the score screen
		if link is -1 then return _end()

		# record the answer
		_logProgress($scope.question.id, index)

		for i in [0..$scope.qset.items[0].items.length-1]
			if link is $scope.qset.items[0].items[i].options.id
				next = $scope.qset.items[0].items[i]
				break

		if $scope.q_data.answers[index].options.feedback
			$scope.feedback = $scope.q_data.answers[index].options.feedback
			$scope.next = next
		else
			manageQuestionScreen next

	# Do stuff when the user submits something in the SA answer box
	$scope.handleShortAnswerInput = ->

		answer = $scope.response.toLowerCase()
		$scope.response = ""

		# Outer loop - loop through every answer set (index 0 is always [All Other Answers] )
		for i in [0...$scope.q_data.answers.length]
			raw_response_str = $scope.q_data.answers[i].text

			# NOTE THAT THIS REGEX IS NOT FINAL. IT NEEDS TO PROPERLY HANDLE ESCAPED COMMAS
			# Javascript doesn't handle negative lookbehind, which is what the Flash engine used
			possible_responses = raw_response_str.trim().split(",")

			# Compare the user's response to each possible answer in the answer set
			for j in [0..possible_responses.length-1]
				if (possible_responses[j].toLowerCase().trim() is answer) # ALSO NOT FINAL REGEX (see above)
					for k in [0...$scope.qset.items[0].items.length]
						if parseInt($scope.q_data.answers[i].options.link) is $scope.qset.items[0].items[k].options.id
							if $scope.q_data.answers[i].options and $scope.q_data.answers[i].options.feedback
								$scope.feedback = $scope.q_data.answers[i].options.feedback
								$scope.next = $scope.qset.items[0].items[k]
							else
								manageQuestionScreen $scope.qset.items[0].items[k]
							_logProgress($scope.question.id, i) # Log the response
							return

		# Fallback in case the user response doesn't match anything. Have to match the link associated with [All Other Answers]
		for answer in $scope.q_data.answers
			if answer.options.isDefault
				link = answer.options.link
				$scope.feedback = answer.options.feedback
		for n in [0...$scope.qset.items[0].items.length]
			if link is $scope.qset.items[0].items[n].id
				if $scope.feedback
					$scope.next = $scope.qset.items[0].items[n]
				else
					manageQuestionScreen $scope.qset.items[0].items[n]

				_logProgress(question.id, 0) # Log the response

	$scope.closeFeedback = ->
		$scope.feedback = ""
		manageQuestionScreen $scope.next
	
	handleMultipleChoice = (q_data) ->
		$scope.type = "mc"

	handleHotspot = (q_data) ->
		$scope.type = "hotspot"
		$scope.question.layout = 1

		img = new Image()
		img.src = $scope.question.image
		img.onload = ->
			scale = CONTAINER_WIDTH / img.width
			scale = 1 if scale > 1

			for answer in $scope.answers
				answer.type = answer.options.hotspot.substr(0,1)
				answer.path = "M0,0"
				if answer.type == '0'
					answer.points = answer.options.hotspot.substr(1).split(",")
					answer.cx = +answer.points[0] * scale + PADDING_LEFT
					answer.cy = +answer.points[1] * scale + PADDING_TOP
					answer.rx = +answer.points[2] * 0.5 * scale
					answer.ry = +answer.points[3] * 0.5 * scale

				if answer.type == '1'
					answer.points = answer.options.hotspot.substr(1).split("),")
					answer.path = ""

					initial = true
					for point in answer.points
						x = point.split("x=")[1].split(",")[0] * scale
						y = point.split("y=")[1].split(")")[0] * scale + PADDING_TOP / 2
						if initial
							answer.path += "M" + x + "," + y
							initial = false
						else
							answer.path += "L" + x + "," + y
				if answer.type == '2'
					answer.points = answer.options.hotspot.substr(1).split(",")
					top = +answer.points[1] * scale
					left = +answer.points[0] * scale + PADDING_LEFT
					width = +answer.points[2] * scale
					height = +answer.points[3] * scale
					answer.path = "M" + left + "," + top + "L" + (left + width) + "," + top + "L" + (left + width) + "," + (top + height) + "L" + left + "," + (top + height)

			$scope.$apply()

	handleShortAnswer = (q_data) ->
		$scope.type = "sa"
		$scope.response = ""

	# Transitional questions are the ones that don't require answers - i.e., narrative and end node
	handleTransitional = (q_data) ->
		# Set the link based on the node type - for end screens, the link is -1 (score screen) and submit the final score
		link = null
		if $scope.question.type is 5
			link = -1
			Materia.Score.submitFinalScoreFromClient q_data.id, $scope.question.text, q_data.options.finalScore
		else
			link = q_data.answers[0].options.link

		$scope.link = link
		$scope.type = "trans"

	handleEmptyNode = -> null

	# Submit the user's response to the logs
	_logProgress = (question_id, answer_index) ->

		question_id = parseInt(question_id)
		answer_index = parseInt(answer_index)

		for i in [0...$scope.qset.items[0].items.length]
			if question_id is $scope.qset.items[0].items[i].options.id then break

		answer_text = null
		if answer_index is -1 then answer_text = "N/A" else answer_text = $scope.qset.items[0].items[i].answers[answer_index].text

		Materia.Score.submitQuestionForScoring $scope.qset.items[0].items[i].id, answer_text

	_end = ->
		console.log 'Engine ended.'
		Materia.Engine.end yes

	Materia.Engine.start($scope.engine)
]

AdventureApp.directive('ngEnter', ->
    return (scope, element, attrs) ->
        element.bind("keydown keypress", (event) ->
            if(event.which == 13 or event.which == 10)
                scope.$apply ->
                    scope.$eval(attrs.ngEnter)
                event.preventDefault()
        )
)

