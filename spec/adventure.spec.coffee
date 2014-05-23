# Specs are imported by and run in the test environment
# by Materia's spec/materia.spec.coffee

client = {}

describe 'Testing framework', ->
	it 'should load widget', (done) ->
		require('./widgets.coffee') 'adventure', ->
			client = this
			done()
	, 15000

adventurePageExpectText = (text, done) ->
	client
		.waitFor '.text', 5000
		.getText '.text', (err, str) ->
			expect(err).toBeNull()
			expect(str).toContain text
		.call(done)

adventureAdvanceToNext = ->
	it 'should be able to advance to the next page', (done) ->
		client
			.waitFor '.trans input', 5000
			.execute "$('.trans input').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)

adventureCloseFeedbackDialog = ->
	it 'should be able to close the feedback dialog', (done) ->
		client
			.waitFor '.feedback input', 5000
			.execute "$('.feedback input').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)

adventureExpectFeedback = (text, done) ->
	client
		.execute "$('.answer[data-index=0]').click()", null, (err) ->
			client
				.waitFor '.feedback.show', 5000
				.getText '.feedback.show', (err, text) ->
					expect(err).toBeNull()
					expect(text).toContain text
				.call(done)

adventureChooseAnswer = (id, done) ->
	client
		.execute "$('.answer[data-link=" + id + "]').click()", null, (err) ->
			expect(err).toBeNull()
			client
				.call(done)

adventureInputShortAnswer = (text, done) ->
	client
		.waitFor '.short-answer'
		.setValue '.short-answer', text
		.execute "$('.sa .trans-button').click()", null, (err) ->
			expect(err).toBeNull()
			client
				.call(done)

describe 'Intro page', ->
	it 'should show narration', (done) ->
		adventurePageExpectText("You're a nurse working in the Emergency Room", done)

	it 'should have an image asset', (done) ->
		client
			.waitFor 'figure img', 5000
			.call(done)

	adventureAdvanceToNext()

describe 'Second page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("After reviewing the patient's chart", done)
	
	it 'should give feedback when offering coffee', (done) ->
		adventureExpectFeedback("While a nice thing to do", done)

	adventureCloseFeedbackDialog()

	it 'should be able to choose to interview the mom', (done) ->
		adventureChooseAnswer(3, done)

describe 'Third page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("You collect the results of your examination", done)

	adventureAdvanceToNext()

describe 'Fourth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("After reviewing your findings", done)

	it 'should be able to choose influenza', (done) ->
		adventureChooseAnswer(7, done)

describe 'Fifth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("Your next step is to contact", done)

	it 'should be able to input "nurse practitioner"', (done) ->
		adventureInputShortAnswer("nurse practitioner", done)

	it 'should give full credit and feedback', (done) ->
		adventureExpectFeedback("Correct", done)

	adventureCloseFeedbackDialog()

describe 'Sixth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("After reviewing the child's symptoms", done)

	adventureAdvanceToNext()

describe 'Seventh page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("Which part of the chart do you think", done)

	it 'should be able to choose lethargia', (done) ->
		client
			.waitFor 'path', 5000
			.execute "$('path:eq(1)').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)

describe 'Eighth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("While lethargy is also a sign", done)

	adventureAdvanceToNext()

describe 'Ninth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("After reviewing your findings", done)

	it 'should be able to choose dehydration', (done) ->
		adventureChooseAnswer(6, done)

describe 'Tenth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("Your next step is to contact", done)

	it 'should be able to input "nurse"', (done) ->
		adventureInputShortAnswer("nurse", done)

	it 'should get it wrong', (done) ->
		adventureExpectFeedback("Incorrect", done)

	adventureCloseFeedbackDialog()

describe 'Eleventh page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("You're ready to contact", done)

	it 'should be able to choose diarrhea', (done) ->
		adventureChooseAnswer(10, done)

	it 'should get feedback', (done) ->
		adventureExpectFeedback("Correct", done)

	adventureCloseFeedbackDialog()

describe 'Twelfth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("The Healthcare Provider has returned", done)

	adventureAdvanceToNext()

describe 'Thirteenth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("greatly improved", done)

	it 'should be able to choose to leave immediately', (done) ->
		adventureChooseAnswer(13, done)

	it 'should get feedback', (done) ->
		adventureExpectFeedback("Not quite!", done)

	adventureCloseFeedbackDialog()

describe 'Fourteenth page', ->
	it 'should show a question', (done) ->
		adventurePageExpectText("Great work!", done)

	adventureAdvanceToNext()

describe 'Score page', ->
	it 'should get a 90', (done) ->
		client.pause(2000)
		client.getTitle (err, title) ->
			expect(err).toBeNull()
			expect(title).toBe('Score Results | Materia')
			client
				.waitFor('.overall_score')
				.getText '.overall_score', (err, text) ->
					expect(err).toBeNull()
					expect(text).toBe('90%')
					client.call(done)
					client.end()

