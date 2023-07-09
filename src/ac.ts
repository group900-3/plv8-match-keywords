function buildTable(words: Record<string, string>) {
  const gotoFn: { [index: number]: { [prop: string]: number } } = {
    0: {},
  };
  const output: {
    [index: number]: string[];
  } = {};

  let state = 0;
  Object.entries(words).forEach(function ([id, word]) {
    let curr = 0;
    for (let i = 0; i < word.length; i++) {
      let l = word[i];
      if (gotoFn[curr] && l in gotoFn[curr]) {
        curr = gotoFn[curr][l];
      } else {
        state++;
        gotoFn[curr][l] = state;
        gotoFn[state] = {};
        curr = state;
        output[state] = [];
      }
    }

    output[curr].push(id);
  });

  let failure: {
    [index: number]: number;
  } = {};
  let xs: number[] = [];

  // f(s) = 0 for all states of depth 1 (the ones from which the 0 state can transition to)
  for (let l in gotoFn[0]) {
    let state = gotoFn[0][l];
    failure[state] = 0;
    xs.push(state);
  }

  while (xs.length) {
    let r = xs.shift();
    // for each symbol a such that g(r, a) = s
    if (!r) break;
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
      } else {
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

function ahoCorasick(words: Record<string, string>, content: string) {
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

export function matchKeywords(ids: string[], words: string[], content: string) {
  const obj = ids.reduce(
    (acc, cur, idx) => ({
      ...acc,
      [cur]: words[idx],
    }),
    {} as Record<string, string>
  );
  return ([] as string[]).concat.apply([], ahoCorasick(obj, content));
}
