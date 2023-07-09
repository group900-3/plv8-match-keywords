CREATE OR REPLACE FUNCTION public.plv8_test (ids text [], words text [], content text)
	RETURNS json
	LANGUAGE plv8
	IMMUTABLE STRICT
	AS $function$
	function buildTable(words) {
		    const gotoFn = {
		        0: {},
		    };
		    const output = {};
		    let state = 0;
		    Object.entries(words).forEach(function ([id, word]) {
		        let curr = 0;
		        for (let i = 0; i < word.length; i++) {
		            let l = word[i];
		            if (gotoFn[curr] && l in gotoFn[curr]) {
		                curr = gotoFn[curr][l];
		            }
		            else {
		                state++;
		                gotoFn[curr][l] = state;
		                gotoFn[state] = {};
		                curr = state;
		                output[state] = [];
		            }
		        }
		        output[curr].push(id);
		    });
		    let failure = {};
		    let xs = [];
		    // f(s) = 0 for all states of depth 1 (the ones from which the 0 state can transition to)
		    for (let l in gotoFn[0]) {
		        let state = gotoFn[0][l];
		        failure[state] = 0;
		        xs.push(state);
		    }
		    while (xs.length) {
		        let r = xs.shift();
		        // for each symbol a such that g(r, a) = s
		        if (!r)
		            break;
		        for (let l in gotoFn[r]) {
		            let s = gotoFn[r][l];
		            xs.push(s);
		            // set state = f(r)
		            let state = failure[r];
		            while (state > 0 && !(l in gotoFn[state])) {
		                state = failure[state];
		            }
		            if (l in gotoFn[state]) {
		                let fs = gotoFn[state][l];
		                failure[s] = fs;
		                output[s] = output[s].concat(output[fs]);
		            }
		            else {
		                failure[s] = 0;
		            }
		        }
		    }
		    return {
		        gotoFn,
		        output,
		        failure,
		    };
		}
		function ahoCorasick(words, content) {
		    const { gotoFn, output, failure } = buildTable(words);
		    let state = 0;
		    const results = [];
		    for (var i = 0; i < content.length; i++) {
		        var l = content[i];
		        while (state > 0 && !(l in gotoFn[state])) {
		            state = failure[state];
		        }
		        if (!(l in gotoFn[state])) {
		            continue;
		        }
		        state = gotoFn[state][l];
		        if (output[state].length) {
		            results.push(output[state]);
		        }
		    }
		    return results;
		}
		function matchKeywords(ids, words, content) {
		    const obj = ids.reduce((acc, cur, idx) => (Object.assign(Object.assign({}, acc), { [cur]: words[idx] })), {});
		    return [].concat.apply([], ahoCorasick(obj, content));
		}
    return matchKeywords(ids,words,content)
$function$
-- SELECT
-- 	plv8_test (ARRAY (
-- 			SELECT
-- 				"id"
-- 			FROM
-- 				"Keywords"),
-- 			ARRAY (
-- 				SELECT
-- 					"title"
-- 				FROM
-- 					"Keywords"),'content to search.');