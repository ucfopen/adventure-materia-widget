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
		# Adventure scores based on TYPE_FINAL_SCORE_FROM_CLIENT, ignore all other log types
		if (strcmp($log->type, Session_Log::TYPE_FINAL_SCORE_FROM_CLIENT) == 0)
		{
			$items;

			# Populate items based on qset version
			if ($this->inst->qset->version == 1) # ['items'][0]['items'] strikes again!
			{
				$items = $this->inst->qset->data['items'][0]['items'];
			}
			else
			{
				$items = $this->inst->qset->data['items'];
			}

			foreach ($items as $item)
			{
				# ignore all qset items that aren't end nodes
				if ($item['options']['type'] != 'end' && $item['options']['type'] != '5') # option->type = 'end' for v2 qsets, option->type = '5' for v1 qsets
				{
					continue;
				}

				# make sure we have the right qset item that matches the provided log, return associated finalScore
				if (trim($log->text) == trim($item['questions'][0]['text']))
				{
					return $item['options']['finalScore'];
				}
			}
		}
		else
		{
			return -1;
		}

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

	protected function details_for_question_answered($log)
	{
		$q     = $this->questions[$log->item_id];
		$score = $this->check_answer($log);

		return [
			'data' => [
				$this->get_ss_question($log, $q),
				$this->get_ss_answer($log, $q),
			],
			'data_style'    => ['question', 'response', 'answer'],
			'score'         => $score,
			'feedback'      => $this->get_feedback($log, $q->answers),
			'type'          => $log->type,
			'style'         => $this->get_detail_style($score),
			'tag'           => 'div',
			'symbol'        => '%',
			'graphic'       => 'score',
			'display_score' => false
		];
	}


	protected function get_score_details()
	{
		$details            = [];
		$destination_table  = [];

		foreach ($this->logs as $log)
		{
			switch ($log->type)
			{
				case Session_Log::TYPE_QUESTION_ANSWERED:
					if ( ! array_key_exists($log->item_id, $this->questions))
					{
					   	break; // contingency for empty nodes (due to previewing)
					}
					if (isset($this->questions[$log->item_id]))
					{
						$details[] = $this->details_for_question_answered($log);
					}
					break;

				case Session_Log::TYPE_FINAL_SCORE_FROM_CLIENT:
					$destination_table[] = [
						'data'          => [$log->text],
						'data_style'    => ['node_text'],
						'score'         => $this->check_answer($log),
						'type'          => $log->type,
						'style'         => 'single_column',
						'tag'           => 'p',
						'symbol'        => '%',
						'graphic'       => 'none',
						'display_score' => false
					];
					break;
			}
		}

		// return an array of tables
		return [
			[
				'title'  => 'Where did you end up?',
				'header' => [],
				'table'  => $destination_table,
			],
			[
				'title'  => 'Responses:',
				'header' => ['Question Score', 'The Question', 'Your Response'],
				'table'  => $details,
			]
		];
	}
}
