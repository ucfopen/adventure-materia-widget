import re
from core.models import Log
from scoring.module import ScoreModule

class Adventure(ScoreModule):

    #helpers for normalizing qsets and ids and traversing nodes
    @staticmethod
    def _is_end_node(self, opts: dict) -> bool:
        t = opts.get("type")
        #so v1 qset knows if its number 5, v2 knows if it is "end"
        return t == 5 or t == "5" or t == "end" or ("finalScore" in opts)
    @staticmethod
    def _normalize_id(self, val):
        if val is None:
            return None
        if isinstance(val, int):
            return val
        s = str(val)
        if s.isdigit():
            return int(s, 10)
        #check if its hex again and parse
        m = re.search(r'([0-9a-fA-F]+)$', s)
        if m:
            suf = m.group(1)
            return int(suf, 16) if re.search(r'[a-fA-F]', suf) else int(suf, 10)
        return None

    #most of the time qsets in materia for django are dicts but older ones may be a list
    def _qset_dict(self):
        q = getattr(self.qset, "data", self.qset) or {}
        if isinstance(q, list):
            q = next((x for x in q if isinstance(x, dict)), {})
        return q if isinstance(q, dict) else {}

    def _items_list(self):
        q = self._qset_dict()
        items = q.get("items") or []
        #v1 everything is in items[0].items
        if (isinstance(items, list) and items and isinstance(items[0], dict)
            and "items" in items[0] and not any(k in items[0] for k in ("type", "questions", "answers"))):
            return items[0].get("items") or []
        return items

    def _iter_nodes(self, items):
        stack = list(items or [])
        while stack:
            it = stack.pop()
            if not isinstance(it, dict):
                continue
            if "items" in it and not any(k in it for k in ("type", "questions", "answers")):
                kids = it.get("items") or []
                if isinstance(kids, list):
                    stack.extend(kids)
                continue
            yield it


    def _match_end_node(self, log):
        #we can do the weird logic of the for loop in here instead of check answer the way php does it
        raw_id = getattr(log, "item_id", None)
        wanted = self._normalize_id(self, raw_id)
        target_text = (getattr(log, "text", "") or "").strip()

        for item in self._iter_nodes(self._items_list()):
            opts = item.get("options") or {}
            if not isinstance(opts, dict):
                continue
            if not self._is_end_node(self, opts):
                continue

            cand = self._normalize_id(self, opts.get("id"))

            if wanted is not None and cand is not None and wanted == cand:
                return item

            if wanted is None:
                qs = item.get("questions") or []
                q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
                if target_text == (q0.get("text", "") or "").strip():
                    return item

        return None


    def _final_text_for_log(self, log):
        node = self._match_end_node(log)
        if node:
            qs = node.get("questions") or []
            q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
            return (q0.get("text", "") or "").strip()
        return (getattr(log, "text", "") or "").strip()

    #now we ok
    def __init__(self, play):
        super().__init__(play)
        qdict = self._qset_dict()
        self.scoreMode = (qdict.get("options") or {}).get("scoreMode", "Normal")

        self._ss_table_title = "Responses:"
        self._ss_table_headers = ["Question Score", "The Question", "Your Response"]

    def check_answer(self, log):
        if self.scoreMode == "Normal":
            if getattr(log, "log_type", None) != Log.LogType.SCORE_FINAL_FROM_CLIENT:
                #php likes to make every log be -1 besides the final one
                return -1
            #where the the old for loop logic happens now
            node = self._match_end_node(log)
            if node:
                opts = node.get("options") or {}
                if self.scoreMode == "Non-Scoring":
                    return 100
                return int(opts.get("finalScore", 0))
            #if nothing matched for whatever reason then php retunrs 0 so
            return 0
        return -1

    #need to ignore this method
    def handle_log_question_answered(self, log):
        pass

    def handle_log_client_final_score(self, log) -> None:
        self.verified_score = 0
        self.total_questions = 0
        final_val = self.check_answer(log)
        self.global_modifiers.append(final_val)

    def calculate_score(self):
        points = self.verified_score + sum(self.global_modifiers)
        self.calculated_percent = max(0, min(100, round(points)))

    def get_score_overview(self):
        return {
            "complete": getattr(self.play, "is_complete", False),
            "score": self.calculated_percent,
            "table": self.get_overview_items(),
            "referrer_url": "",
            "created_at": "",
            "auth": "",
        }

    def details_for_question_answered(self, log):
        question = self.get_question_by_item_id(log.item_id)
        if not isinstance(question, dict):
            return None
        answers = question.get("answers") or []
        score = self.check_answer(log)
        return {
            "id": log.item_id,
            "data": [
                self.get_ss_question(log, question),
                self.get_ss_answer(log, question),
                log.value,
            ],
            "data_style": ["question", "response"],
            "score": score,
            "feedback": self.get_feedback(log, answers),
            "type": log.log_type,
            "style": self.get_detail_style(score),
            "symbol": "%",
            "graphic": "score",
            "display_score": False,
        }

    def get_score_details(self):
        rows = []
        for log in self.logs:
            if log.log_type == Log.LogType.SCORE_QUESTION_ANSWERED:
                if log is None:
                    continue
                q = self.get_question_by_item_id(log.item_id)
                if q is not None:
                    rows.append(self.details_for_question_answered(log))
            elif log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:
                score = self.check_answer(log)
                text = self._final_text_for_log(log)
                item_id = getattr(log, "item_id", 0)
                older_qset = (item_id == 0 and text != "Blank Destination! Be sure to edit or remove this node before publishing.")
                blank_node = (item_id == 0 and text == "Blank Destination! Be sure to edit or remove this node before publishing.")
                rows.append({
                    "node_id": item_id,
                    "data": [text, score],
                    "data_style": ["text", "score"],
                    "score": score,
                    "type": log.log_type,
                    "style": "final_score",
                    "symbol": "%",
                    "graphic": "score",
                    "display_score": False,
                    "older_qset": older_qset,
                    "blank_node": blank_node,
                })
        headers = self._ss_table_headers
        return [{
            "title": self._ss_table_title,
            "headers": headers,
            "header": headers,
            "headers": headers, # usually we go by headers in base score module
            "header": headers, # adventure goes by headers for some reason?? legacy compatibility, harmless
            "table": rows,
        }]

    #overrided: in some cases item_id can be an object but still null so it would crash
    def get_question_by_item_id(self, item_id):
        if item_id is None:
            return None
        target = str(item_id)
        for node in self._iter_nodes(self._items_list()):
            opts = node.get("options") or {}
            cand_ids = [opts.get("id"), node.get("id")]
            if any(str(cid) == target for cid in cand_ids if cid is not None):
                return node
        return None

