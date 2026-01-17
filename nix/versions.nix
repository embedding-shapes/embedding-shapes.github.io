{ pkgs, lib, gitDir, mdToHtml }:

let
  versionsMd = { name, summary ? "Versions", file ? null, follow ? false }:
    pkgs.runCommandLocal name {
      nativeBuildInputs = [ pkgs.git pkgs.gnused pkgs.gnugrep ];
    } ''
      set -euo pipefail
      export GIT_DIR=${gitDir}
      export GIT_OPTIONAL_LOCKS=0

      summary=${lib.escapeShellArg summary}
      file=${lib.escapeShellArg (if file == null then "" else file)}
      log="$TMPDIR/log.tsv"

      if [ -n "$file" ]; then
        ${pkgs.git}/bin/git log ${lib.optionalString follow "--follow"} --date=short --format='%H%x09%ad%x09%s' -- "$file" > "$log" 2>/dev/null || true
      else
        ${pkgs.git}/bin/git log --date=short --format='%H%x09%ad%x09%s' > "$log" 2>/dev/null || true
      fi

      if [ ! -s "$log" ]; then
        : > "$out"
        exit 0
      fi

      {
        echo '<details class="versions">'
        echo "<summary>$summary</summary>"
        echo

        while IFS="$(printf '\t')" read -r hash date subject; do
          short="$(printf '%.7s' "$hash")"
          esc_subject="$(printf '%s' "$subject" | ${pkgs.gnused}/bin/sed -e 's/&/&amp;/g' -e 's/</&lt;/g' -e 's/>/&gt;/g')"

          echo '<details class="version">'
          echo "<summary>$date <code>$short</code> $esc_subject</summary>"
          echo

          echo '````````diff'
          diff_full="$TMPDIR/diff.full"
          diff_body="$TMPDIR/diff.body"
          diff_word="$TMPDIR/diff.word"

          if [ -z "$file" ]; then
            ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" 2>/dev/null > "$diff_body" || true
          else
            status="$(${pkgs.git}/bin/git show --no-color --format= --name-status -1 "$hash" -- "$file" 2>/dev/null | ${pkgs.gnused}/bin/sed -n '1s/\t.*$//p')"

            case "$status" in
              A*|D*)
                ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" -- "$file" 2>/dev/null > "$diff_full" || true
                ;;
              *)
                ${pkgs.git}/bin/git show --no-color --format= --unified=0 --word-diff=porcelain "$hash" -- "$file" 2>/dev/null > "$diff_full" || true
                ;;
            esac

            ${pkgs.gnused}/bin/sed -n '/^@@ /,$p' "$diff_full" > "$diff_body"

            if ! printf '%s' "$status" | ${pkgs.gnugrep}/bin/grep -qE '^(A|D)'; then
              ${pkgs.gnused}/bin/sed '/^~$/d' "$diff_body" > "$diff_word"
              if ${pkgs.gnugrep}/bin/grep -qE '^[+-]' "$diff_word"; then
                cat "$diff_word" > "$diff_body"
              else
                ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" -- "$file" 2>/dev/null > "$diff_full" || true
                ${pkgs.gnused}/bin/sed -n '/^@@ /,$p' "$diff_full" > "$diff_body"
              fi
            fi
          fi

          cat "$diff_body"
          echo '````````'
          echo
          echo '</details>'
          echo
        done < "$log"

        echo '</details>'
      } > "$out"
    '';

  versionsHtml = args:
    if gitDir == null then ""
    else mdToHtml (versionsMd args);

in {
  postVersionsHtml = filename: versionsHtml {
    name = "post-versions-${lib.removeSuffix ".md" filename}.md";
    file = "posts/${filename}";
    follow = true;
  };

  repoVersions = versionsHtml {
    name = "repo-versions.md";
    summary = "Repository Versions";
  };
}

