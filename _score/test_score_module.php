<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group Adventure
 */
class Test_Score_Modules_Adventure extends \Basetest
{

	protected function _get_qset()
	{
		return json_decode('{
			"items":[
				{
					"items":[
						{
							"name":null,
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":100,
									"text":"Multiple Choice Answer",
									"options":[
										{
											"validScore":1,
											"feedback":null,
											"link":1
										}
									],
									"id":0
								}
							],
							"questions":[
								{
									"text":"Multiple Choice Question"
								}
							],
							"options":[
								{
									"randomize":1,
									"type":2,
									"layout":1,
									"id":0
								}
							],
							"id":0
						},
						{
							"name":null,
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":0,
									"text":"[All Other Answers]",
									"options":[
										{
											"validScore":1,
											"feedback":null,
											"link":2,
											"isDefault":1
										}
									],
									"id":0
								},
								{
									"value":100,
									"text":"Correct Response",
									"options":[
										{
											"isShortcut":1,
											"validScore":1,
											"feedback":null,
											"link":2
										}
									],
									"id":0
								}
							],
							"questions":[
								{
									"text":"Short Answer Question"
								}
							],
							"options":[
								{
									"randomize":1,
									"type":4,
									"layout":1,
									"id":0
								}
							],
							"id":0
						}
					],
					"name":"",
					"options":{
						"scoreStyle":0
					},
					"assets":[],
					"rand":null
				}
			],
			"name":"",
			"options":{},
			"assets":[],
			"rand":null,
			"id":0
		}');
	}

	protected function _get_quest_qset()
	{
		return json_decode('{
			"items":[
				{
					"items":[
						{
							"name":null,
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":0,
									"text":"Unscored Response One",
									"options":{
											"validScoreModification":1,
											"scoreModification":0,
											"feedback":null,
											"link":1
									},
									"id":0
								},
								{
									"value":0,
									"text":"Unscored Response Two",
									"options":{
											"validScoreModification":1,
											"scoreModification":0,
											"feedback":null,
											"link":2
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Unscored Response"
								}
							],
							"options":{
								"randomize":1,
								"type":2,
								"layout":1,
								"id":0
							},
							"id":0


						},
						{
							"name":null,
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":0,
									"text":"Scored Incorrect Answer",
									"options":{
											"validScoreModification":1,
											"scoreModification":-10,
											"feedback":null,
											"link":1
									},
									"id":0
								},
								{
									"value":0,
									"text":"Scored Correct Answer",
									"options":{
											"validScoreModification":1,
											"scoreModification":10,
											"feedback":null,
											"link":2
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Scored Response"
								}
							],
							"options":{
								"randomize":1,
								"type":2,
								"layout":1,
								"id":0
							},
							"id":0


						},
						{
							"name":null,
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":0,
									"text":"[All Other Answers]",
									"options":{
											"validScoreModification":1,
											"scoreModification":-10,
											"feedback":null,
											"link":1,
											"isDefault":1
									},
									"id":0
								},
								{
									"value":0,
									"text":"Short Correct Answer",
									"options":{
											"validScoreModification":1,
											"scoreModification":10,
											"feedback":null,
											"link":2
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Short Answer Question"
								}
							],
							"options":{
								"randomize":1,
								"type":4,
								"layout":1,
								"id":0
							},
							"id":0


						}
					],
					"name":"",
					"options":{
						"initialScore":100,
						"scoreStyle":1
					},
					"assets":[],
					"rand":null
				}
			],
			"name":"",
			"options":{},
			"assets":[],
			"rand":null,
			"id":0
		}');
	}

	protected function _get_destination_qset()
	{
		return json_decode('{
			"items":[
				{
					"items":[
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":100,
									"text":"Correct MC Answer",
									"options":{
										"feedback":null,
										"link":1
									},
									"id":0
								},
								{
									"value":0,
									"text":"Wrong MC Answer",
									"options":{
											"feedback":null,
											"link":1
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Multiple Choice Question"
								}
							],
							"options":{
								"randomize":1,
								"type":2,
								"layout":1,
								"id":0
							},
							"id":0
						},
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":0,
									"text":"[All Other Answers]",
									"options":{
											"feedback":null,
											"link":2,
											"isDefault":1
									},
									"id":0
								},
								{
									"value":100,
									"text":"Correct Answer",
									"options":{
										"feedback":null,
										"link":3,
										"isShortcut":1
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Short Answer Question"
								}
							],
							"options":{
								"randomize":1,
								"type":4,
								"layout":1,
								"id":0
							},
							"id":0
						},
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[],
							"questions":[
								{
									"text":"Full Credit"
								}
							],
							"options":{
								"finalScore":100,
								"id":0,
								"type":5,
								"proceedText":"Continue",
								"layout":1
							},
							"id":0
						},
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[],
							"questions":[
								{
									"text":"Half Credit"
								}
							],
							"options":{
								"finalScore":50,
								"id":0,
								"type":5,
								"proceedText":"Continue",
								"layout":1
							},
							"id":0
						}

					],
					"name":"",
					"options":{
			     			"scoreStyle":2
					},
					"assets":[],
					"rand":null
				}
			],
			"name":"",
			"options":{},
			"assets":[],
			"rand":null,
			"id":0
		}');
	}

	protected function _makeWidget($qset_type = 0)
	{
		$this->_asAuthor();

		$title = 'ADVENTURE SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Adventure');
		$qset = null;

		switch ($qset_type)
		{
			case 0:
				$qset = (object) ['version' => 1, 'data' => $this->_get_qset()];
				break;

			case 1:
				$qset = (object) ['version' => 1, 'data' => $this->_get_quest_qset()];
				break;

			case 2:
				$qset = (object) ['version' => 1, 'data' => $this->_get_destination_qset()];
				break;
		}

		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_check_answer()
	{
		$inst = $this->_makeWidget(0);

		$playSession = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $playSession);

		$logs = array();
		$logs[] = json_decode('{
			"text":"Multiple Choice Answer",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');

		$logs[] = json_decode('{
			"text":"Correct Response",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":0,
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($playSession, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$thisScore = \Materia\Api::widget_instance_play_scores_get($playSession);

		$this->assertInternalType('array', $thisScore);
		$this->assertEquals(100, $thisScore[0]['perc']);
	}

	public function test_check_answer_quest()
	{
		$inst = $this->_makeWidget(1);

		$playSession = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $playSession);

		$logs = array();
		$logs[] = json_decode('{
			"text":"Unscored Response One",
			"type":1006,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');

		$logs[] = json_decode('{
			"text":"Scored Correct Answer",
			"type":1006,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');

		$logs[] = json_decode('{
			"text":"[All Other Answers]",
			"type":1006,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":12
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":0,
			"game_time":13
		}');

		$output = \Materia\Api::play_logs_save($playSession, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$thisScore = \Materia\Api::widget_instance_play_scores_get($playSession);

		$this->assertInternalType('array', $thisScore);
		$this->assertEquals(100, $thisScore[0]['perc']);
	}

	public function test_check_answer_destination()
	{
		$inst = $this->_makeWidget(2);

		$playSession = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $playSession);

		$logs = array();

		$logs[] = json_decode('{
			"text":"Correct MC Answer",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":11
		}');

		$logs[] = json_decode('{
			"text":"[All Other Answers]",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":12
		}');

		$logs[] = json_decode('{
			"text":"Half Credit",
			"type":1007,
			"value":0,
			"item_id":0,
			"game_time":13
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":0,
			"game_time":14
		}');

		$output = \Materia\Api::play_logs_save($playSession, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$thisScore = \Materia\Api::widget_instance_play_scores_get($playSession);

		$this->assertInternalType('array', $thisScore);
		$this->assertEquals(50, $thisScore[0]['perc']);
	}

}