<?php
/**
 * Materia
 * It's a thing
 *
 * @package	    Materia
 * @version    1.0
 * @author     UCF New Media
 * @copyright  2011 New Media
 * @link       http://kogneato.com
 */


/**
 * NEEDS DOCUMENTATION
 *
 * The widget managers for the Materia package.
 *
 * @package	    Main
 * @subpackage  scoring
 * @category    Modules
  * @author      ADD NAME HERE
 */

namespace Materia;

class Score_Modules_Adventure extends Score_Module
{
	/**
	 * NEEDS DOCUMENTATION
	 * @param unknown NEEDS DOCUMENTATION
	 */
	public function check_answer($log)
	{
		// $q = $this->questions[$log->item_id];
		trace('tracing log id...'.$log->item_id);
		trace('log text: '.$log->text);

		if (strcmp($log->item_id, '0') == 0)
		{
			foreach ($this->inst->qset->data['items'][0]['items'] as $item)
			{
				if ($log->text == $item['questions'][0]['text'])
				{
					return $item['options']['finalScore'];
				}
			}
		}
		else
		{
			return -1;
		}

		// this should never be returned.
		return 0;
	}

	protected function handle_log_question_answered($log)
	{
		// Verified score and total questions remain at 0 as the final score log type determines the widget's score.
	}

	protected function handle_log_client_final_score($log)
	{
		$this->verified_score = 0;
		$this->total_questions = 0;
		$this->global_modifiers[] = $this->check_answer($log);
	}

	protected function calculate_score()
	{
		$global_mod = array_sum($this->global_modifiers);
		$points = $this->verified_score + $global_mod;
		$this->calculated_percent = round($points);

		if ($this->calculated_percent < 0) $this->calculated_percent = 0;
	}

	protected function get_score_details()
	{
		$details  = [];
		$title 		= 'Responses:';
		$header   = ['Question Score', 'The Question', 'Your Response', 'Correct Answer'];

		foreach ($this->logs as $log)
		{
			switch ($log->type)
			{
				case Session_Log::TYPE_QUESTION_ANSWERED:
					if ($q = $this->questions[$log->item_id])
					{
						$feedback;
						$question_text = $q->questions[0]['text'];
						$correct_answers = 'N/A';

						$score       = $this->check_answer($log);
						$user_answer = $this->get_score_page_answer($log);
						$feedback    = $this->get_feedback($log, $q->answers);
						$details[]   = ['data'          => [$question_text, $user_answer, $correct_answers],
													  'data_style'    => ['question', 'response', 'answer'],
													  'score'         => $score,
													  'feedback'      => $feedback,
													  'type'          => $log->type,
													  'style'         => $this->get_detail_style($score),
													  'tag'           => 'div',
													  'symbol'        => '%',
													  'graphic'       => 'score',
													  'display_score' => false];
					}
					break;

				case Session_Log::TYPE_FINAL_SCORE_FROM_CLIENT:
					$score          = $this->check_answer($log);
					$user_answer    = $this->get_score_page_answer($log);
					$details[]      = ['data' => [$user_answer],
									'data_style'    => ['node_text'],
									'score'         => $score,
									'type'          => $log->type,
									'style'         => 'single_column',
									'tag'           => 'p',
									'symbol'        => '%',
									'graphic'       => 'final',
									'display_score' => true];
					break;
			}
		}

		// return an array of tables
		return [['title'    => $title,
						 'header'   => $header,
						 'table'    => $details]];
	}

	/**
	 * NEEDS DOCUMENTATION
	 */
	public function validate_scores()
	{
		$value = parent::validate_scores();
		return $value;
	}
}