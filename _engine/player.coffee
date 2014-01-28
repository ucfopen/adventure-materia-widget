Namespace('Adventure').Engine = do ->
	_qset = null
	_base_url = null
	LAYOUT_IMAGE_ONLY = 0	# Layout that contains only an image
	LAYOUT_TEXT_ONLY = 1 	# Layout that contains only text
	LAYOUT_HORIZ_TEXT = 2 	# Horizontal layout that contains text and then an image
	LAYOUT_HORIZ_IMAGE = 3 	# Horizontal layout that contains an image and then text
	LAYOUT_VERT_TEXT = 4 	# Vertical layout that contains text and then an image
	LAYOUT_VERT_IMAGE = 5 	# Vertical layout that contains an image and then text

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_base_url = instance.base_url
		_init(instance.name)

	_init = (title) ->
		# document.oncontextmenu = -> false                  # Disables right click.
		# document.addEventListener 'mousedown', (e) ->
		# 	if e.button is 2 then false else true          # Disables right click.

		# Update screen with basic widget information (title)
		screen = $('#overview-screen-template').html()
		data =
			title : title

		$('#overview-screen').html(_.template(screen, data))

		# Kick off the questions starting with the root node
		_manageQuestionScreen(_qset.items[0].items[0])

	# Update the screen depending on the question type (narrative, mc, short answer, hotspot, etc)
	_manageQuestionScreen = (q_data) ->

		switch q_data.options.type
			when -1 then _end() # technically this shouldn't be called - the end call is made is _handleAnswerSelection
			when 1, 5 then _handleTransitional(q_data)
			when 2 then _handleMultipleChoice(q_data)
			when 3 then _handleHotspot(q_data)
			when 4 then _handleShortAnswer(q_data)
			else
				_handleEmptyNode # Should hopefully only happen on preview, when empty nodes are allowed

	# Handles selection of MC answer choices and transitional buttons (narrative and end screen)
	_handleAnswerSelection = (e) ->
		target = $(e.target)

		if parseInt(target.attr('data-link')) is -1 then _end() # link to -1 indicates the widget should advance to the score screen

		for i in [0.._qset.items[0].items.length-1]
			if parseInt(target.attr('data-link')) is _qset.items[0].items[i].options.id
				_manageQuestionScreen _qset.items[0].items[i]
				break

		_logProgress(target.attr('data-id'), target.attr('data-index')) # record the answer

	_handleMultipleChoice = (q_data) ->

		node_screen = $('#node-screen-template').html()

		question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		# check if question has an associated asset (for now, just an image)
		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		answers = []

		for i in [0..q_data.answers.length-1]
			answer =
				text : q_data.answers[i].text,
				link : q_data.answers[i].options.link,
				index : i
			answers.push answer

		data =
			question : question,
			answers : answers,
			type : "mc"

		# output question data to the page
		$('#node-screen').html(_.template(node_screen, data))

		# add listener for answer selection
		$('.answer').on 'click', _handleAnswerSelection

	_handleHotspot = (q_data) ->

		########## TEMP CODE ############

		node_screen = $('#node-screen-template').html()

		question =
			text : "Hi! I should be a hotspot, but instead I'm a multiple choice question! Wait, WHAT'S GOING ON?!",
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		answers = []

		for i in [0..q_data.answers.length-1]
			answer =
				text : q_data.answers[i].text,
				link : q_data.answers[i].options.link,
				index : i
			answers.push answer

		data =
			question : question,
			answers : answers,
			type : "mc"

		$('#node-screen').html(_.template(node_screen, data))

		$('.answer').on 'click', _handleAnswerSelection

		########### END TEMP CODE ####################

	_handleShortAnswer = (q_data) ->

		node_screen = $('#node-screen-template').html()

		question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		# SA doesn't provide answers to the DOM - input is vetted in _handleShortAnswerInput
		data =
			question : question,
			type : "sa"

		# Check if question has an associated asset (for now, just an image)
		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		# Output
		$('#node-screen').html(_.template(node_screen, data))

		# Listener for the intput box
		$('#sa-answer').keypress (e) ->
			if e.which == 10 or e.which == 13
				_handleShortAnswerInput(e)

		# Do stuff when the user submits something in the SA answer box
		_handleShortAnswerInput = (e) ->
			target = $(e.target)

			# Outer loop - loop through every answer set (index 0 is always [All Other Answers] )
			for i in [0..q_data.answers.length-1]
				raw_response_str = q_data.answers[i].text
				# NOTE THAT THIS REGEX IS NOT FINAL. IT NEEDS TO PROPERLY HANDLE ESCAPED COMMAS
				# Javascript doesn't handle negative lookbehind, which is what the Flash engine used
				possible_responses = raw_response_str.trim().split(",")

				# Compare the user's response to each possible answer in the answer set
				for j in [0..possible_responses.length-1]
					answer = target[0].value.toLowerCase()

					if (possible_responses[j].toLowerCase().trim() is answer) # ALSO NOT FINAL REGEX (see above)
						for k in [0.._qset.items[0].items.length-1]
							if parseInt(q_data.answers[i].options.link) is _qset.items[0].items[k].options.id
								_manageQuestionScreen _qset.items[0].items[k]
								_logProgress(question.id, i) # Log the response
								return

			# Fallback in case the user response doesn't match anything. Have to match the link associated with [All Other Answers]
			for n in [0.._qset.items[0].items.length-1]
				if parseInt(q_data.answers[0].options.link) is _qset.items[0].items[n].id
					_manageQuestionScreen _qset.items[0].items[n]
					_logProgress(question.id, 0) # Log the response

			# _manageQuestionScreen _qset.items[0].items[] # should be [All Other Answers]

	# Transitional questions are the ones that don't require answers - i.e., narrative and end node
	_handleTransitional = (q_data) ->

		node_screen = $('#node-screen-template').html()

		question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		# check if question has an associated asset (for now, just an image)
		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		# Set the link based on the node type - for end screens, the link is -1 (score screen) and submit the final score
		link = null
		if question.type is 5
			link = -1
			Materia.Score.submitFinalScoreFromClient q_data.id, question.text, q_data.options.finalScore
		else
			link = q_data.answers[0].options.link

		data =
			question : question,
			type : "trans",
			link : link

		# Output to the screen
		$('#node-screen').html(_.template(node_screen, data))

		# Set the listener for the continue button
		$('#trans-continue').on 'click', _handleAnswerSelection

	_handleEmptyNode = ->

	# Submit the user's response to the logs
	_logProgress = (question_id, answer_index) ->

		question_id = parseInt(question_id)
		answer_index = parseInt(answer_index)

		for i in [0.._qset.items[0].items.length-1]
			if question_id is _qset.items[0].items[i].options.id then break

		answer_text = null
		if answer_index is -1 then answer_text = "N/A" else answer_text = _qset.items[0].items[i].answers[answer_index].text

		Materia.Score.submitQuestionForScoring _qset.items[0].items[i].id, answer_text


	_end = ->
		Materia.Engine.end yes

	#public
	manualResize: true
	start: start