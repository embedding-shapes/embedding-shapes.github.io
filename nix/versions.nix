{ pkgs, lib, gitDir, mdToHtml }:

let
  versionsMd = { name, summary ? "Versions", file ? null, files ? [], follow ? false }:
    let
      trackedFiles =
        if files != [] then files
        else lib.optional (file != null) file;
    in pkgs.runCommandLocal name {
      nativeBuildInputs = [ pkgs.git pkgs.gnused pkgs.gnugrep ];
    } ''
      set -euo pipefail
      export GIT_DIR=${gitDir}
      export GIT_OPTIONAL_LOCKS=0

      summary=${lib.escapeShellArg summary}
      log="$TMPDIR/log.tsv"
      tracked_files=()
      ${lib.concatMapStringsSep "\n" (trackedFile:
        "tracked_files+=(${lib.escapeShellArg trackedFile})"
      ) trackedFiles}

      if [ "''${#tracked_files[@]}" -gt 0 ]; then
        ${pkgs.git}/bin/git log \
          ${lib.optionalString (follow && (builtins.length trackedFiles == 1)) "--follow"} \
          --date=short --format='%H%x09%ad%x09%s' -- "''${tracked_files[@]}" > "$log" 2>/dev/null || true
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

          if [ "''${#tracked_files[@]}" -eq 0 ]; then
            ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" 2>/dev/null > "$diff_body" || true
          elif [ "''${#tracked_files[@]}" -gt 1 ]; then
            # Keep post-level history easy to follow by showing the combined patch
            # for all translation files touched by the commit.
            ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" -- "''${tracked_files[@]}" 2>/dev/null > "$diff_body" || true
          else
            file="''${tracked_files[0]}"
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
  postVersionsHtml = { filename ? null, filenames ? [], summary ? "Versions" }:
    let
      normalizedFilenames =
        if filenames != [] then filenames
        else lib.optional (filename != null) filename;
    in versionsHtml {
      name =
        if normalizedFilenames == [] then "post-versions.md"
        else "post-versions-${lib.removeSuffix ".md" (builtins.head normalizedFilenames)}.md";
      inherit summary;
      files = map (postFilename: "posts/${postFilename}") normalizedFilenames;
      follow = builtins.length normalizedFilenames == 1;
    };

  repoVersionsHtml = summary: versionsHtml {
    name = "repo-versions.md";
    inherit summary;
  };
}
