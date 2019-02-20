function escapeRegexp(text) {
  return text.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&").replace(/\*/g, "S*");
}

function createCensorRegexp(patterns) {
  console.log(patterns.join("|"));
  // return new RegExp(`((?<!\\w)(?:${patterns.join("|")}))(?!\\w)`, "ig");
  return new RegExp(`(?<!\\w)(${patterns.join("|")})(?!\\w)`, "ig");
  // return new RegExp(`((?<!\\w)(${patterns.join("|")}))(?!\\w)`, "ig");
}

export function censorFn(
  censoredWords,
  replacementLetter,
  watchedWordsRegularExpressions
) {
  console.log("censorRegexp");
  let patterns = [];

  replacementLetter = replacementLetter || "&#9632;";

  if (censoredWords && censoredWords.length) {
    patterns = censoredWords.split("|");
    if (!watchedWordsRegularExpressions) {
      patterns = patterns.map(t => `(${escapeRegexp(t)})`);
    }
  }
  console.log(patterns);

  if (patterns.length) {
    let censorRegexp;
    console.log("patterns");

    try {
      if (watchedWordsRegularExpressions) {
      console.log("11");
        censorRegexp = new RegExp(
          "((?:" + patterns.join("|") + "))(?![^\\(]*\\))",
          "ig"
        );
      } else {
        console.log("22");
        censorRegexp = new RegExp(
          `((?<!\\w)(?:${patterns.join("|")}))(?!\\w)`,
          "ig"
        );
        console.log(censorRegexp);
      }

      if (censorRegexp) {
        console.log("44");
        return function(text) {
          let original = text;

          try {
            let m = censorRegexp.exec(text);
            const fourCharReplacement = new Array(5).join(replacementLetter);

            while (m && m[0]) {
              if (m[0].length > original.length) {
                return original;
              } // regex is dangerous
              if (watchedWordsRegularExpressions) {
                text = text.replace(censorRegexp, fourCharReplacement);
              } else {
                const replacement = new Array(m[0].length + 1).join(
                  replacementLetter
                );
                text = text.replace(
                  createCensorRegexp([escapeRegexp(m[0])]),
                  replacement
                );
              }
              m = censorRegexp.exec(text);
            }

            return text;
          } catch (e) {
            return original;
          }
        };
      }
    } catch (e) {
      // fall through
    }
  }

  return function(t) {
    return t;
  };
}

export function censor(text, censoredWords, replacementLetter) {
  return censorFn(censoredWords, replacementLetter)(text);
}
